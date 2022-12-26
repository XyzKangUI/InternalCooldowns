local _, ICD = ...

ICD.InternalCooldowns = {}
local lib = ICD.InternalCooldowns

local _G = getfenv(0)
local GetItemInfoInstant = _G.GetItemInfoInstant
local GetInventoryItemTexture = _G.GetInventoryItemTexture
local GetMacroInfo = _G.GetMacroInfo
local GetActionInfo = _G.GetActionInfo
local GetActionCooldown = _G.GetActionCooldown
local GetInventoryItemCooldown = _G.GetInventoryItemCooldown
local GetInventoryItemID = _G.GetInventoryItemID
local CooldownFrame_Set = _G.CooldownFrame_Set
local GetItemInfo = _G.GetItemInfo
local substr = _G.string.sub
local playerGUID
local GetTime = _G.GetTime
local unpack = _G.unpack
local tonumber = _G.tonumber
local type = _G.type
local ipairs = _G.ipairs
local hooksecurefunc = _G.hooksecurefunc
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

lib.spellToItem = lib.spellToItem or { }
lib.cooldownStartTimes = lib.cooldownStartTimes or { }
lib.cooldownDurations = lib.cooldownDurations or { }
lib.cooldowns = lib.cooldowns or nil

local enchantProcTimes = { }

if not lib.eventFrame then
    lib.eventFrame = CreateFrame("Frame")
    lib.eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    lib.eventFrame:RegisterEvent("PLAYER_LOGIN")
    lib.eventFrame:SetScript("OnEvent", function(frame, event, ...)
        frame.lib[event](frame.lib, event, ...)
    end)
end
lib.eventFrame.lib = lib

local INVALID_EVENTS = {
    SPELL_DISPEL = true,
    SPELL_DISPEL_FAILED = true,
    SPELL_STOLEN = true,
    SPELL_AURA_REMOVED = true,
    SPELL_AURA_REMOVED_DOSE = true,
    SPELL_AURA_BROKEN = true,
    SPELL_AURA_BROKEN_SPELL = true,
    SPELL_CAST_FAILED = true,
}

local slots = {
    AMMOSLOT = 0,
    INVTYPE_HEAD = 1,
    INVTYPE_NECK = 2,
    INVTYPE_SHOULDER = 3,
    INVTYPE_BODY = 4,
    INVTYPE_CHEST = 5,
    INVTYPE_WAIST = 6,
    INVTYPE_LEGS = 7,
    INVTYPE_FEET = 8,
    INVTYPE_WRIST = 9,
    INVTYPE_HAND = 10,
    INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 },
    INVTYPE_CLOAK = 15,
    INVTYPE_WEAPONMAINHAND = 16,
    INVTYPE_2HWEAPON = 16,
    INVTYPE_WEAPON = { 16, 17 },
    INVTYPE_HOLDABLE = 17,
    INVTYPE_SHIELD = 17,
    INVTYPE_WEAPONOFFHAND = 17,
}

function lib:PLAYER_LOGIN()
    local bt4 = IsAddOnLoaded("Bartender4")
    local dm = IsAddOnLoaded("Dominos")

    playerGUID = UnitGUID("player")

    -- PaperDollFrame Hook
    hooksecurefunc("PaperDollItemSlotButton_Update", lib.GetInventoryItemCooldown)

    -- TrinketMenu support
    if IsAddOnLoaded("TrinketMenu") then
        TrinketMenu.UpdateWornCooldowns = lib.TMGetInventoryItemCooldown
    end

    -- Actionbars
    if bt4 and dm then
        return
    elseif bt4 then
        for i = 1, 120 do
            local button = _G["BT4Button" .. i]
            if button and not button.CDHook then
                button.GetCooldown = lib.BT4GetActionCooldown
                button.CDHook = true
            end
        end
    else
        hooksecurefunc("ActionButton_UpdateCooldown", lib.GetActionCooldown)
    end
end

local function checkSlotForEnchantID(slot, enchantID)
    local itemID = GetInventoryItemID("player", slot)
    if not itemID then
        return false
    end
    local _, enchant = GetItemInfoInstant(itemID)
    return enchant == enchantID, itemID
end

local function isEquipped(itemID)
    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemID)
    local slot = slots[equipLoc]

    if type(slot) == "table" then
        for _, v in ipairs(slot) do
            if GetInventoryItemID("player", v) == itemID then
                return true
            end
        end
    else
        if GetInventoryItemID("player", slot) == itemID then
            return true
        end
    end
    return false
end

function lib:COMBAT_LOG_EVENT_UNFILTERED()
    local _, event, _, sourceGUID, _, _, _, destGUID, _, _, _, spellID = CombatLogGetCurrentEventInfo()

    playerGUID = playerGUID or UnitGUID("player")
    if ((destGUID == playerGUID and (sourceGUID == nil or sourceGUID == destGUID)) or sourceGUID == playerGUID) and not INVALID_EVENTS[event] and substr(event, 0, 6) == "SPELL_" then
        local itemID = lib.spellToItem[spellID]
        if itemID then
            if type(itemID) == "table" then
                for _, v in ipairs(itemID) do
                    if isEquipped(v) then
                        self:SetCooldownFor(v, spellID)
                    end
                end
                return
            else
                if isEquipped(itemID) then
                    self:SetCooldownFor(itemID, spellID)
                end
                return
            end
        end

        -- Tests for enchant procs
        local enchantID = lib.enchants[spellID]
        if enchantID then
            local enchantID, slot1, slot2 = unpack(enchantID)
            local enchantPresent, itemID, first, second
            enchantPresent, itemID = checkSlotForEnchantID(slot1, enchantID)
            if enchantPresent then
                first = itemID
                if (enchantProcTimes[slot1] or 0) < GetTime() - (lib.cooldowns[spellID] or 45) then
                    enchantProcTimes[slot1] = GetTime()
                    self:SetCooldownFor(itemID, spellID)
                    return
                end
            end

            enchantPresent, itemID = checkSlotForEnchantID(slot2, enchantID)
            if enchantPresent then
                second = itemID
                if (enchantProcTimes[slot2] or 0) < GetTime() - (lib.cooldowns[spellID] or 45) then
                    enchantProcTimes[slot2] = GetTime()
                    self:SetCooldownFor(itemID, spellID)
                    return
                end
            end

            if first and second then
                if enchantProcTimes[slot1] < enchantProcTimes[slot2] then
                    self:SetCooldownFor(first, spellID)
                else
                    self:SetCooldownFor(second, spellID)
                end
            end
        end

        local metaID = lib.metas[spellID]
        if metaID then
            local id = GetInventoryItemID("player", 1)
            if id and id ~= 0 then
                self:SetCooldownFor(id, spellID)
            end
            return
        end

        local talentID = lib.talents[spellID]
        if talentID then
            self:SetCooldownFor(("%s: %s"):format(UnitClass("player"), talentID), spellID)
            return
        end
    end
end

function lib:SetCooldownFor(itemID, spellID)
    local duration = lib.cooldowns[spellID] or 45
    lib.cooldownStartTimes[itemID] = GetTime()
    lib.cooldownDurations[itemID] = duration
end

local function cooldownReturn(id)
    if not id or not lib.cooldownStartTimes[id] or not lib.cooldownDurations[id] then
        return nil
    end

    local startTime = lib.cooldownStartTimes[id]
    local duration = lib.cooldownDurations[id]
    if GetTime() > startTime + duration then
        return 0, 0, 0
    else
        return startTime, duration, 1
    end
end

function lib.GetInventoryItemCooldown(self)
    local start, duration, enable = GetInventoryItemCooldown("player", self:GetID())

    if not enable or enable == 0 then
        local itemID = GetInventoryItemID("player", self:GetID())

        if itemID then
            local start, duration, running = cooldownReturn(itemID)

            local cooldown = _G[self:GetName() .. "Cooldown"];
            if start then
                CooldownFrame_Set(cooldown, start, duration, running);
            end
        end
    end
end


function lib.TMGetInventoryItemCooldown(maybeGlobal)
    local itemID1 = GetInventoryItemID("player", 13)
    local itemID2 = GetInventoryItemID("player", 14)
    if itemID1 or itemID2 then
        local start1, duration1, enable1 = GetInventoryItemCooldown("player", 13)
        local start2, duration2, enable2 = GetInventoryItemCooldown("player", 14)
        local start3, duration3, running3 = cooldownReturn(itemID1)
        local start4, duration4, running4 = cooldownReturn(itemID2)
        if start3 then
            start1 = start3
            duration1 = duration3
            enable1 = running3
        end
        if start4 then
            start2 = start4
            duration2 = duration4
            enable2 = running4
        end
        CooldownFrame_Set(TrinketMenu_Trinket0Cooldown, start1, duration1, enable1)
        CooldownFrame_Set(TrinketMenu_Trinket1Cooldown, start2, duration2, enable2)
    end

    if not maybeGlobal then
        TrinketMenu.WriteWornCooldowns()
    end
end

function lib.GetActionCooldown(self)
    local actionType, actionID, actionSubType = GetActionInfo(self.action)
    local itemTable = {}
    local firstTexture = GetInventoryItemTexture("player", 13)
    local secondTexture = GetInventoryItemTexture("player", 14)
    if firstTexture then
        itemTable[firstTexture] = 13
    end
    if secondTexture then
        itemTable[secondTexture] = 14
    end

    if actionType == "item" then
        local start, duration, running = cooldownReturn(actionID)
        if start then
            CooldownFrame_Set(self.cooldown, start, duration, running, false);
        end
    elseif actionType == "macro" then
        local _, tex = GetMacroInfo(actionID)
        local inventorySlot = itemTable[tex]
        if inventorySlot then
            actionID = GetInventoryItemID("player", inventorySlot)
            if actionID then
                local start, duration, running = cooldownReturn(actionID)
                if start then
                    CooldownFrame_Set(self.cooldown, start, duration, running, false);
                end
            end
        end
    end
end


function lib.BT4GetActionCooldown(self)
    local actionType, actionID, actionSubType = GetActionInfo(self._state_action)
    local itemTable = {}
    local firstTexture = GetInventoryItemTexture("player", 13)
    local secondTexture = GetInventoryItemTexture("player", 14)
    if firstTexture then
        itemTable[firstTexture] = 13
    end
    if secondTexture then
        itemTable[secondTexture] = 14
    end

    if actionType == "item" then
        local start, duration, running = cooldownReturn(actionID)
        if start then
            return start, duration, running
        end
    elseif actionType == "macro" then
        local _, tex = GetMacroInfo(actionID)
        local inventorySlot = itemTable[tex]
        if inventorySlot then
            actionID = GetInventoryItemID("player", inventorySlot)
            if actionID then
                local start, duration, running = cooldownReturn(actionID)
                if start then
                    return start, duration, running
                end
            end
        end
    end
    return GetActionCooldown(self._state_action)
end
