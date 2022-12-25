local _, ICD = ...

local lib = ICD.InternalCooldowns

local _G = getfenv(0)
local pairs = _G.pairs
local ipairs = _G.ipairs
local wipe = _G.table.wipe
local tinsert = _G.table.insert
local type = _G.type

-- Format is spellID = itemID | {itemID, itemID, ... itemID}
local spellToItem = {
	-- Mists of Pandaria T16 Raids
	[146250] = {105111, 104862, 102302, 105360, 104613, 105609},	-- Thok's Tail Tip
	[146245] = {104993, 104744, 102298, 105242, 104495, 105491},	-- Evil Eye of Galakras
	[148899] = {104961, 104712, 102295, 105210, 104463, 105459},	-- Fusion-Fire Core

	-- Timeless Isle
	[146296] = {103689, 103989},	-- Alacrity of Xuen

	-- Mists of Pandaria T15 Raids
	--[138759] = {95726, 94515, 96098, 96470, 96842},	-- Fabled Feather of Ji-Kun

	-- Shado-Pan Assault Valor Items
	[138702] = 94508,	-- Brutal Talisman of the Shado-Pan Assault
	[138704] = 94510,	-- Volatile Talisman of the Shado-Pan Assault
	[138700] = 94511,	-- Vicious Talisman of the Shado-Pan Assault
	
	-- Pandaria PVP
	[126700] = {84937, 91415, 91768, 94415, 100505, 102699},	-- Gladiator's Insignia of Victory
	[127928] = 87574,	-- Coren's Cold Chromium Coaster
	
	-- Mists of Pandaria T14 Raids
	[126533] = {86790, 86131, 87063},	-- Vial of Dragon's Blood
	[126577] = {86792, 86133, 87065},	-- Light of the Cosmos	
	[126588] = {86805, 86147, 87075},	-- Qin-Xi's Polarizing Seal
	[126552] = {86791, 86132, 87057},	-- Bottle of Infinite Stars
	[126583] = {86802, 86144, 87072},	-- Lei Shin's Final Orders
	[126641] = {86885, 86327, 87163},	-- Spirits of the Sun
	[126647] = {86881, 86323, 87160},	-- Stuff of Nightmares
	[126650] = {86890, 86332, 87167},	-- Terror in the Mists
	[126658] = {86894, 86336, 87172},	-- Darkmist Vortex
	[126660] = {86907, 86388, 87175},	-- Essence of Terror

	-- Mists of Pandaria Darkmoon Cards
	[128984] = 79328,			-- Relic of Xuen (agi)
	[128985] = 79331,			-- Relic of Yu'lon
	[128986] = 79327,			-- Relic of Xuen (str)
	[128987] = 79330,			-- Relic of Chi Ji

	-- Mists of Pandaria Brewfest
	[127923] = 87572,			-- Mithril Wristwatch
	[127914] = 87573,			-- Thousand-Year Pickled Egg
	[127926] = 87574,			-- Coren's Cold Chromium Coaster

	-- Mists of Pandaria Instances
	[126266] = 81133,			-- Empty Fruit Barrel
	[126513] = 81138,			-- Carbonic Carbuncle
	[126476] = 81192,			-- Vision of the Predator
	[126236] = {81243, 85181},	-- Iron Protector Talisman
	[126483] = 81125,			-- Windswept Pages
	[126489] = 81267,			-- Searing Words

	-- Darkmoon Cards
	[89091] = 62047,			-- Darkmoon Card: Volcano

	-- Tol Barad factions
	[91192] = {62467, 62472},	-- Mandala of Stirring Patterns
	[91047] = {62465, 62470},	-- Stump of Time

	-- Valour Vendor 4.0
	[92233] = 58182,			-- Bedrock Talisman

	-- Dragon Soul Heroic 410
	[109804] = 77989,			-- Seal of the Seven Signs
	[109776] = 77990,			-- Soulshifter Vortex
	[109789] = 77991,			-- Insignia of the Corrupted Mind
	[109744] = 77992,			-- Creche of the Final Dragon
	[109711] = 77993,			-- Starcatcher Compass

	-- Dragon Soul Normal 397
	[107986] = 77206,			-- Soulshifter Vortex
	[107982] = {77202, 77203 ,77204},	-- Starcatcher Compass, Insignia of the Corrupted Mind, Seal of the Seven Signs
	[107988] = 77205,			-- Creche of the Final Dragon

	-- Dragon Soul LFR 384
	[109802] = 77969,			-- Seal of the Seven Signs
	[109774] = 77970,			-- Soulshifter Vortex
	[109787] = 77971,			-- Insignia of the Corrupted Mind
	[109742] = 77972,			-- Creche of the Final Dragon
	[109709] = 77973,			-- Starcatcher Compass

	-- Season 11 Arena 403
	[105135] = 73643,			-- Cataclysmic Gladiator's Insignia of Conquest
	[105137] = 73497,			-- Cataclysmic Gladiator's Insignia of Dominance
	[105139] = 73491,			-- Cataclysmic Gladiator's Insignia of Victory

	-- Season 11 Arena 390
	[102432] = 72455,			-- Ruthless Gladiator's Insignia of Victory
	[102435] = 72449,			-- Ruthless Gladiator's Insignia of Dominance
	[102439] = 72309,			-- Ruthless Gladiator's Insignia of Conquest

	-- Cataclysm Dungeon 378
	[102659] = 72897,			-- Arrow of Time
	[102667] = 72900,			-- Veil of Lies
	[109993] = 74035,			-- Master Pit Fighter
	--[102662] = 72898,			-- Foul Gift of the Demon Lord //DO NOT USE, overwrites the actual use cooldown with the internal one.
	--[102664] = 72899,			-- Varo'then's Brooch //DO NOT USE, overwites the actual use cooldown with the internal one.
	--[102660] = 72901,			-- Rosary of Light //Yet another item with a use and an equip proc. This needs a workaround eventually.

	-- Cataclysm Raid 397
	[97125] = 69112,			-- The Hungerer
	[97139] = 69150,			-- Matrix Restabilizer Haste
	[97140] = 69150,			-- Matrix Restabilizer Crit
	[97141] = 69150,			-- Matrix Restabilizer Mastery
	[97136] = 69149,			-- Eye of Blazing Power	//Not sure if that'll work, it's a heal on a party member.
	[97129] = 69138,			-- Spidersilk Spindle

	-- Cataclysm Raid 384
	[96911] = 68927,			-- The Hungerer
	[96977] = 68994,			-- Matrix Restabilizer Haste
	[96978] = 68994,			-- Matrix Restabilizer Crit
	[96979] = 68994,			-- Matrix Restabilizer Mastery
	[96966] = 68983,			-- Eye of Blazing Power	//Not sure if that'll work, it's a heal on a party member.
	[96945] = 68981,			-- Spidersilk Spindle

	-- Cataclysm Raid 372
	[92320] = 65105,			-- Theralion's Mirror
	[92355] = 65048,			-- Symbiotic Worm
	[92349] = 65026,			-- Prestor's Talisman of Machination
	[92345] = 65072,			-- Heart of Rage
	[92332] = 65124,			-- Fall of Mortality
	[92351] = 65140,			-- Essence of the Cyclone
	[92342] = 65118,			-- Crushing Weight
	[92318] = 65053,			-- Bell of Enraging Resonance
	--[92331] = 65029,			-- Jar of Ancient Remedies ==DO NOT USE, overwrites the actual use cooldown with the internal one.

	-- Cataclysm Raid 359
	[92108] = 59520,			-- Unheeded Warning
	[91024] = 59519,			-- Theralion's Mirror
	[92235] = 59332,			-- Symbiotic Worm
	[92124] = 59441,			-- Prestor's Talisman of Machination
	[91816] = 59224,			-- Heart of Rage
	[91184] = 59500,			-- Fall of Mortality
	[92126] = 59473,			-- Essence of the Cyclone
	[91821] = 59506,			-- Crushing Weight
	[91007] = 59326,			-- Bell of Enraging Resonance
	--[91322] = 59354,			-- Jar of Ancient Remedies //DO NOT USE, overwrites the actual use cooldown with the internal one.

	-- Cataclysm Dungeon 346
	[90992] = 56407,			-- Anhuur's Hymnal
	[91149] = 56414,			-- Blood of Isiset
	[92087] = 56295,			-- Grace of the Herald
	[91364] = 56393,			-- Heart of Solace
	[92091] = 56328,			-- Key to the Endless Chamber
	[92184] = 56347,			-- Leaden Despair
	[92094] = 56427,			-- Left Eye of Rajh
	[92174] = 56280,			-- Porcelain Crab
	[91143] = 56377,			-- Rainsong
	[91368] = 56431,			-- Right Eye of Rajh
	[91002] = 56400,			-- Sorrowsong
	[91139] = 56351,			-- Tear of Blood
	[90898] = 56339,			-- Tendrils of Burrowing Dark
	[92205] = 56449,			-- Throngus's Finger
	[90887] = 56320,			-- Witching Hourglass

	-- Cataclysm Dungeon and World drops 308-333
	[90989] = 55889,			-- Anhuur's Hymnal
	[91147] = 55995,			-- Blood of Isiset
	[91363] = 55868,			-- Heart of Solace
	[92096] = 56102,			-- Left Eye of Rajh
	[91370] = 56100,			-- Right Eye of Rajh
	[90996] = 55879,			-- Sorrowsong
	[92208] = 56121,			-- Throngus's Finger
	[92052] = 66969,			-- Heart of the Vile
	[92069] = 55795,			-- Key to the Endless Chamber
	[92179] = 55816,			-- Leaden Despair
	[91141] = 55854,			-- Rainsong
	[91138] = 55819,			-- Tear of Blood
	[90896] = 55810,			-- Tendrils of Burrowing Dark
	[92052] = 55266,			-- Grace of the Herald
	[90885] = 55787,			-- Witching Hourglass

	-- Cataclysm Quest rewards
	[92166] = {65803, 65805, 65804, 55237}, -- Harrison's Insignia of Panache, Schnotzz's Medallion of Command, Talisman of Sinister Order, Porcelain Crab 

	-- PVP Lvl 85
	[85027] = 61045,			-- Vicious Gladiator's Insignia of Dominance
	[85032] = 61046,			-- Vicious Gladiator's Insignia of Victory
	[85022] = 61047,			-- Vicious Gladiator's Insignia of Conquest
	[92218] = 64762,			-- Bloodthirsty Gladiator's Insignia of Dominance
	[92216] = 64763,			-- Bloodthirsty Gladiator's Insignia of Victory
	[92220] = 64761,			-- Bloodthirsty Gladiator's Insignia of Conquest

	-- Random WotLK stuff
	[64411] = 46017,			-- Val'anyr, Hammer of Ancient Kings

	[60065] = {44914, 40684, 49074},	-- Anvil of the Titans, Mirror of Truth, Coren's Chromium Coaster
	[60488] = 40373,					-- Extract of Necromatic Power
	[64713] = 45518,					-- Flare of the Heavens
	[60064] = {44912, 40682, 49706},	-- Flow of Knowledge, Sundial of the Exiled, Mithril Pocketwatch

	[67703] = {47303, 47115},	-- Death's Choice, Death's Verdict (AGI)
	[67708] = {47303, 47115},	-- Death's Choice, Death's Verdict (STR)
	[67772] = {47464, 47131},	-- Death's Choice, Death's Verdict (Heroic) (AGI)
	[67773] = {47464, 47131},	-- Death's Choice, Death's Verdict (Heroic) (STR)

	-- ICC epix
	-- Rep rings
	[72416] = {50398, 50397},
	[72412] = {50402, 50401},
	[72418] = {50399, 50400},
	[72414] = {50404, 50403},

	-- Deathbringer's Will
	[71485] = 50362,
	[71492] = 50362,
	[71486] = 50362,
	[71484] = 50362,
	[71491] = 50362,
	[71487] = 50362,

	-- Deathbringer's Will (Heroic)
	[71556] = 50363,
	[71560] = 50363,
	[71558] = 50363,
	[71561] = 50363,
	[71559] = 50363,
	[71557] = 50363,

	[71403] = 50198,			-- Needle-Encrusted Scorpion
	[71610] = 50359,			-- Althor's Abacus
	[71633] = 50352,			-- Corpse-tongue coin

	-- ICC trinkets
	[71601] = 50353,			-- Dislodged Foreign Object
	[71584] = 50358,			-- Purified Lunar Dust
	[71401] = 50342,			-- Whispering Fanged Skull
	[71605] = 50360,			-- Phylactery of the Nameless Lich
	
	-- Heroic ICC trinkets
	[71541] = 50343,			-- Whispering Fanged Skull
	[71641] = 50366,			-- Althor's Abacus
	[71639] = 50349,			-- Corpse-tongue coin
	[71644] = 50348,			-- Dislodged Foreign Object
	[71636] = 50365,			-- Phylactery of the Nameless Lich

	-- RS trinkets
	[75458] = 54569,			-- Sharpened Twilight Scale
	[75466] = 54572,			-- Charred Twilight Scale
	[75477] = 54571,			-- Petrified Twilight Scale

	-- Heroic RS trinkets
	[75456] = 54590,			-- Sharpened Twilight Scale
	[75473]	= 54588,			-- Charred Twilight Scale
	[75480]	= 54591,			-- Petrified Twilight Scale

	-- DK T9 2pc
	[67117] = {48501, 48502, 48503, 48504, 48505, 48472, 48474, 48476, 48478, 48480, 48491, 48492, 48493, 48494, 48495, 48496, 48497, 48498, 48499, 48500, 48486, 48487, 48488, 48489, 48490, 48481, 48482, 48483, 48484, 48485},

	-- WotLK Epix
	[67671] = 47214,			-- Banner of Victory
	[67669] = 47213,			-- Abyssal Rune 
	[64772] = 45609,			-- Comet's Trail
	[65024] = 46038,			-- Dark Matter
	[60443] = 40371,			-- Bandit's Insignia
	[64790] = 45522,			-- Blood of the Old God
	[60203] = 42990,			-- Darkmoon Card: Death
	[60494] = 40255,			-- Dying Curse
	[65004] = 65005,			-- Elemental Focus Stone
	[60492] = 39229,			-- Embrace of the Spider
	[60530] = 40258,			-- Forethought Talisman
	[60437] = 40256,			-- Grim Toll
	[49623] = 37835,			-- Je'Tze's Bell
	[65019] = 45931,			-- Mjolnir Runestone
	[64741] = 45490,			-- Pandora's Plea
	[65014] = 45286,			-- Pyrite Infuser
	[65003] = 45929,			-- Sif's Remembrance
	[60538] = 40382,			-- Soul of the Dead
	[58904] = 43573,			-- Tears of Bitter Anguish
	[60062] = {40685, 49078},	-- The Egg of Mortal Essence, Ancient Pickled Egg
	[64765] = 45507,			-- The General's Heart

	-- WotLK Blues
	[51353]	= 38358,			-- Arcane Revitalizer
	[60218] = 37220,			-- Essence of Gossamer
	[60479] = 37660,			-- Forge Ember
	[51348] = 38359,			-- Goblin Repetition Reducer
	[63250] = 45131,			-- Jouster's Fury
	[63250] = 45219,			-- Jouster's Fury
	[60302] = 37390,			-- Meteorite Whetstone
	[54808] = 40865,			-- Noise Machine
	[60483] = 37264,			-- Pendulum of Telluric Currents
	[52424] = 38675,			-- Signet of the Dark Brotherhood
	[55018] = 40767,			-- Sonic Booster
	[52419] = 38674,			-- Soul Harvester's Charm
	-- [18350] = 37111,			-- Soul Preserver, no internal cooldown
	[60520] = 37657,			-- Spark of Life
	[60307] = 37064,			-- Vestige of Haldor

	-- Greatness cards
	[60233] = {44253, 44254, 44255, 42987},		-- Greatness, AGI
	[60235] = {44253, 44254, 44255, 42987},		-- Greatness, SPI
	[60229] = {44253, 44254, 44255, 42987},		-- Greatness, INT
	[60234] = {44253, 44254, 44255, 42987},		-- Greatness, STR

	-- Vanilla Epix
	[23684] = 19288,			-- Darkmoon Card: Blue Dragon
}

-- spell ID = {enchant ID, slot1[, slot2]}
local enchants = {
	-- MoP
	[104993] = {4442, 16},			-- Jade Spirit
	--[118334] = {4444, 16, 17},		-- Dancing Steel - Agility
	--[118335] = {4444, 16, 17},		-- Dancing Steel - Strength
	--[120032] = {4444, 16, 17},		-- Dancing Steel combo spell
	--[116660] = {4446, 16},			-- River's Song
	[116631] = {4445, 16},			-- Colossus

	-- Cataclysm
	[74245] = {4099, 16, 17},		-- Landslide
	[74241] = {4097, 16},			-- Power Torrent
	[74221] = {4083, 16, 17},		-- Hurricane
	[74224] = {4084, 16},			-- Heartsong
	[75170] = {4115, 15},			-- Lightweave Embroidery (Rank 2)
	[75176] = {4118, 15},			-- Swordguard Embroidery (Rank 2)
	[75173] = {4116, 15},			-- Darkglow Embroidery (Rank 2)
	[95712] = {4175, 18},			-- Gnomish X-Ray Scope

	-- WotLK
	[55637] = {3722, 15},			-- Lightweave Embroidery (Rank 1)
	[55775] = {3730, 15},			-- Swordguard Embroidery (Rank 1)
	[55767] = {3728, 15},			-- Darkglow Embroidery (Rank 1)
	[59626] = {3790, 16},			-- Black Magic
}

-- ICDs on metas assumed to be 45 sec. Needs testing.
local metas = {
	-- I've commented these two out, because there aren't really any tactical decisions you could make based on them.
	-- [55382] = 41401,				-- Insightful Earthsiege Diamond
	-- [32848] = 25901,				-- Insightful Earthstorm Diamond

	[23454] = 25899,				-- Brutal Earthstorm Diamond
	[55341] = 41385,				-- Invigorating Earthsiege Diamond
	[18803] = 25893,				-- Mystical Skyfire Diamond
	[32845]	= 25898,				-- Tenacious Earthstorm Diamond
	[39959] = 32410,				-- Thundering Skyfire Diamond
	[55379] = 41400,				-- Thundering Skyflare Diamond
}

-- Spell ID => cooldown, in seconds
-- If an item isn't in here, 45 sec is assumed.
local cooldowns = {
	-- Mists of Pandaria T16 Raids
	[146250] = 115,	-- Thok's Tail Tip
	[146245] = 55,	-- Evil Eye of Galakras
	[148899] = 85,	-- Fusion-Fire Core

	-- Timeless Isle
	[146296] = 115,	-- Alacrity of Xuen

	-- Mists of Pandaria T15 Raids
	--[138759] = 22,	-- Fabled Feather of Ji-Kun

	-- Shado-Pan Assault Valor Items
	[138702] = 75,			-- Brutal Talisman of the Shado-Pan Assault
	[138704] = 45,			-- Volatile Talisman of the Shado-Pan Assault
	[138700] = 105,			-- Vicious Talisman of the Shado-Pan Assault

	-- Pandaria PVP
	[126700] = 50,			-- Gladiator's Insignia of Victory
	[127928] = 60,			-- Coren's Cold Chromium Coaster

	-- Mists of Pandaria T14 Raids
	[126658] = 105,			-- Darkmist Vortex
	[126660] = 105,			-- Essence of Terror
	[126650] = 105,			-- Terror in the Mists

	-- Mists of Pandara Darkmoon Cards
	[128984] = 55,			-- Relic of Xuen (AGI)
	[128985] = 50,			-- Relic of Yu'lon
	[128987] = 50,			-- Relic of Chi Ji

	-- Mists of Pandaria Instances
	[126368] = 30,			-- Empty Fruit Barrel
	[126513] = 105,			-- Carbonic Carbuncle
	[126473] = 105,			-- Vision of the Predator
	[126237] = 60,			-- Iron Protector Talisman
	[126482] = 65,			-- Windswept Pages
	[126490] = 85,			-- Searing Words

	-- Tol Barad factions
	[91192] = 50,			-- Mandala of Stirring Patterns, confirm!
	[91047] = 75,			-- Stump of Time

	-- Valour Vendor 4.0
	[92233] = 30,			-- Bedrock Talisman

	-- Dragon Soul Heroic 410
	[109804] = 90,			-- Seal of the Seven Signs
	[109776] = 90,			-- Soulshifter Vortex
	[109789] = 90,			-- Insignia of the Corrupted Mind
	[109744] = 90,			-- Creche of the Final Dragon
	[109711] = 90,			-- Starcatcher Compass

	-- Dragon Soul Normal 397
	[107986] = 90,			-- Soulshifter Vortex
	[107982] = 90,			-- Starcatcher Compass, Insignia of the Corrupted Mind, Seal of the Seven Signs
	[107988] = 90,			-- Creche of the Final Dragon

	-- Dragon Soul LFR 384
	[109802] = 90,			-- Seal of the Seven Signs
	[109774] = 90,			-- Soulshifter Vortex
	[109787] = 90,			-- Insignia of the Corrupted Mind
	[109742] = 90,			-- Creche of the Final Dragon
	[109709] = 90,			-- Starcatcher Compass

	-- Cataclysm Dungeon 378
	[102659] = 50,			-- Arrow of Time
	[102667] = 50,			-- Veil of Lies
	[109993] = 50,			-- Master Pit Fighter

	-- Cataclysm Raid 397
	[97125] = 60,			-- The Hungerer
	[97139] = 105,			-- Matrix Restabilizer Haste
	[97140] = 105,			-- Matrix Restabilizer Crit
	[97141] = 105,			-- Matrix Restabilizer Mastery
	[97129] = 60,			-- Spidersilk Spindle

	-- Cataclysm Raid 384
	[96911] = 60,			-- The Hungerer
	[96977] = 105,			-- Matrix Restabilizer Haste
	[96978] = 105,			-- Matrix Restabilizer Crit
	[96979] = 105,			-- Matrix Restabilizer Mastery
	[96945] = 60,			-- Spidersilk Spindle

	-- Cataclysm Raid 372
	[92320] = 50,			-- Theralion's Mirror, confirm!
	[92355] = 30,			-- Symbiotic Worm
	[92349] = 75,			-- Prestor's Talisman of Machination
	[92345] = 90,			-- Heart of Rage
	[92332] = 75,			-- Fall of Mortality, confirm!
	[92351] = 50,			-- Essence of the Cyclone
	[92342] = 75,			-- Crushing Weight, confirm!
	[92318] = 100,			-- Bell of Enraging Resonance
	--[92331] = 30,			-- Jar of Ancient Remedies

	-- Cataclysm Raid 359
	[91024] = 50,			-- Theralion's Mirror, confirm!
	[92235] = 30,			-- Symbiotic Worm
	[92124] = 75,			-- Prestor's Talisman of Machination
	[91816] = 90,			-- Heart of Rage, confirm!
	[91184] = 75,			-- Fall of Mortality, confirm!
	[92126] = 50,			-- Essence of the Cyclone
	[91821] = 75,			-- Crushing Weight, confirm!
	[91007] = 100,			-- Bell of Enraging Resonance
	--[91322] = 30,			-- Jar of Ancient Remedies
	[92108] = 50,			-- Unheeded Warning, confirm!

	-- Cataclysm Dungeon 346
	[90992] = 50,			-- Anhuur's Hymnal
	[91149] = 100,			-- Blood of Isiset
	[92087] = 50,			-- Grace of the Herald
	[91364] = 100,			-- Heart of Solace
	[92091] = 75,			-- Key to the Endless Chamber
	[92184] = 30,			-- Leaden Despair
	[92094] = 50,			-- Left Eye of Rajh
	[92174] = 80,			-- Porcelain Crab, confirm!
	[91143] = 75,			-- Rainsong
	[91368] = 50,			-- Right Eye of Rajh
	[91002] = 10,			-- Sorrowsong, very spammy
	[91139] = 75,			-- Tear of Blood
	[90898] = 75,			-- Tendrils of Burrowing Dark
	[92205] = 60,			-- Throngus's Finger
	[90887] = 75,			-- Witching Hourglass

	-- Cataclysm Dungeon and World drops 308-333
	[90989] = 50,			-- Anhuur's Hymnal
	[91147] = 100,			-- Blood of Isiset
	[91363] = 100,			-- Heart of Solace
	[92096] = 50,			-- Left Eye of Rajh
	[91370] = 50,			-- Right Eye of Rajh
	[90996] = 10,			-- Sorrowsong, very spammy
	[92208] = 60,			-- Throngus's Finger
	[92052] = 50,			-- Heart of the Vile
	[92069] = 75,			-- Key to the Endless Chamber
	[92179] = 30,			-- Leaden Despair
	[91141] = 75,			-- Rainsong
	[91138] = 75,			-- Tear of Blood
	[90896] = 75,			-- Tendrils of Burrowing Dark
	[92052] = 50,			-- Grace of the Herald
	[90885] = 75,			-- Witching Hourglass

	-- Cataclysm Quest rewards
	[92166] = 80,			-- Harrison's Insignia of Panache, Schnotzz's Medallion of Command, Talisman of Sinister Order, Porcelain Crab

	-- PvP Lvl 85
	[85027] = 50,			-- Vicious Gladiator's Insignia of Dominance
	[85032] = 50,			-- Vicious Gladiator's Insignia of Victory
	[85022] = 50,			-- Vicious Gladiator's Insignia of Conquest
	[92218] = 50,			-- Bloodthirsty Gladiator's Insignia of Dominance
	[92216] = 50,			-- Bloodthirsty Gladiator's Insignia of Victory
	[92220] = 50,			-- Bloodthirsty Gladiator's Insignia of Conquest

	-- MoP enchants
	[104993] = 50,			-- Jade Spirit
	--[118334] = 60,			-- Dancing Steel - Agility
	--[118335] = 60,			-- Dancing Steel - Strength
	--[120032] = 60,			-- Dancing Steel combo spell?	
	--[116660] = 30,			-- River's Song
	[116631] = 3,			-- Colossus

	-- Cataclysm enchants
	[74224] = 20,			-- Heartsong

	-- ICC rep rings
	[72416] = 60,
	[72412] = 60,
	[72418] = 60,
	[72414] = 60,

	[60488] = 15,
	[51348] = 10,
	[51353] = 10,
	[54808] = 60,
	[55018] = 60,
	[52419] = 30,
	[59620] = 90,
	[55382] = 15,
	[32848] = 15,
	[55341] = 90,
	[48517] = 30,
	[48518] = 30,
	[47755] = 12,

	-- Deathbringer's Will
	[71485] = 105,
	[71492] = 105,
	[71486] = 105,
	[71484] = 105,
	[71491] = 105,
	[71487] = 105,

	-- Deathbringer's Will (Heroic)
	[71556] = 105,
	[71560] = 105,
	[71558] = 105,
	[71561] = 105,
	[71559] = 105,
	[71557] = 105,

	-- Phylactery of the Nameless Lich
	[71605] = 90,
	-- Phylactery of the Nameless Lich (Heroic)
	[71636] = 90,

	-- RS trinkets
	[75458] = 45,			-- Sharpened Twilight Scale
	[75466] = 45,			-- Charred Twilight Scale
	[75477] = 45,			-- Petrified Twilight Scale

	-- Heroic RS trinkets
	[75456] = 45,			-- Sharpened Twilight Scale
	[75473] = 45,			-- Charred Twilight Scale
	[75480] = 45,			-- Petrified Twilight Scale

	-- Black Magic
	[59626] = 35,
}

-- Procced spell effect ID = unique name
-- The name doesn't matter, as long as it's non-numeric and unique to the ICD.
local talents = {
	-- Druid
	[48517] = "Eclipse",
	[48518] = "Eclipse",
	--[16886] = "Nature's Grace", -- resets after 60s or with Eclipses

	-- Hunter
	[56453] = "Lock and Load",

	-- Death Knight
	[52286] = "Will of the Necropolis",

	-- Priest
	[47755] = "Rapture",
}

--[[
	Don't edit past this line
]]--

-- Upgrade this data into the lib
lib.spellToItem = lib.spellToItem or { }
lib.cooldowns = lib.cooldowns or { }
lib.enchants = lib.enchants or { }
lib.metas = lib.metas or { }
lib.talents = lib.talents or { }



local tt, tts = { }, { }
local function merge(t1, t2)
	wipe(tts)
	for _, v in ipairs(t1) do
		tts[v] = true
	end
	for _, v in ipairs(t2) do
		if not tts[v] then
			tinsert(t1, v)
		end
	end
end

for k, v in pairs(spellToItem) do
	local e = lib.spellToItem[k]
	if e and e ~= v then
		if type(e) == "table" then
			if type(v) ~= "table" then
				wipe(tt)
				tinsert(tt, v)
			end
			merge(e, tt)
		else
			lib.spellToItem[k] = {e, v}
		end
	else
		lib.spellToItem[k] = v
	end
end

for k, v in pairs(cooldowns) do
	lib.cooldowns[k] = v
end

for k, v in pairs(enchants) do
	lib.enchants[k] = v
end

for k, v in pairs(metas) do
	lib.metas[k] = v
end

for k, v in pairs(talents) do
	lib.talents[k] = v
end