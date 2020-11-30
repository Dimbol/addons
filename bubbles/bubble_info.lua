bubble_info = {
    [768] = {type="Indi", effect="Regen",      debuff=false},
    [769] = {type="Indi", effect="Poison",     debuff=true},
    [770] = {type="Indi", effect="Refresh",    debuff=false},
    [771] = {type="Indi", effect="Haste",      debuff=false},
    [772] = {type="Indi", effect="STR",        debuff=false},
    [773] = {type="Indi", effect="DEX",        debuff=false},
    [774] = {type="Indi", effect="VIT",        debuff=false},
    [775] = {type="Indi", effect="AGI",        debuff=false},
    [776] = {type="Indi", effect="INT",        debuff=false},
    [777] = {type="Indi", effect="MND",        debuff=false},
    [778] = {type="Indi", effect="CHR",        debuff=false},
    [779] = {type="Indi", effect="Fury",       debuff=false},
    [780] = {type="Indi", effect="Barrier",    debuff=false},
    [781] = {type="Indi", effect="Acumen",     debuff=false},
    [782] = {type="Indi", effect="Fend",       debuff=false},
    [783] = {type="Indi", effect="Precision",  debuff=false},
    [784] = {type="Indi", effect="Voidance",   debuff=false},
    [785] = {type="Indi", effect="Focus",      debuff=false},
    [786] = {type="Indi", effect="Attunement", debuff=false},
    [787] = {type="Indi", effect="Wilt",       debuff=true},
    [788] = {type="Indi", effect="Frailty",    debuff=true},
    [789] = {type="Indi", effect="Fade",       debuff=true},
    [790] = {type="Indi", effect="Malaise",    debuff=true},
    [791] = {type="Indi", effect="Slip",       debuff=true},
    [792] = {type="Indi", effect="Torpor",     debuff=true},
    [793] = {type="Indi", effect="Vex",        debuff=true},
    [794] = {type="Indi", effect="Languor",    debuff=true},
    [795] = {type="Indi", effect="Slow",       debuff=true},
    [796] = {type="Indi", effect="Paralysis",  debuff=true},
    [797] = {type="Indi", effect="Gravity",    debuff=true},
    [798] = {type="Geo",  effect="Regen",      debuff=false},
    [799] = {type="Geo",  effect="Poison",     debuff=true},
    [800] = {type="Geo",  effect="Refresh",    debuff=false},
    [801] = {type="Geo",  effect="Haste",      debuff=false},
    [802] = {type="Geo",  effect="STR",        debuff=false},
    [803] = {type="Geo",  effect="DEX",        debuff=false},
    [804] = {type="Geo",  effect="VIT",        debuff=false},
    [805] = {type="Geo",  effect="AGI",        debuff=false},
    [806] = {type="Geo",  effect="INT",        debuff=false},
    [807] = {type="Geo",  effect="MND",        debuff=false},
    [808] = {type="Geo",  effect="CHR",        debuff=false},
    [809] = {type="Geo",  effect="Fury",       debuff=false},
    [810] = {type="Geo",  effect="Barrier",    debuff=false},
    [811] = {type="Geo",  effect="Acumen",     debuff=false},
    [812] = {type="Geo",  effect="Fend",       debuff=false},
    [813] = {type="Geo",  effect="Precision",  debuff=false},
    [814] = {type="Geo",  effect="Voidance",   debuff=false},
    [815] = {type="Geo",  effect="Focus",      debuff=false},
    [816] = {type="Geo",  effect="Attunement", debuff=false},
    [817] = {type="Geo",  effect="Wilt",       debuff=true},
    [818] = {type="Geo",  effect="Frailty",    debuff=true},
    [819] = {type="Geo",  effect="Fade",       debuff=true},
    [820] = {type="Geo",  effect="Malaise",    debuff=true},
    [821] = {type="Geo",  effect="Slip",       debuff=true},
    [822] = {type="Geo",  effect="Torpor",     debuff=true},
    [823] = {type="Geo",  effect="Vex",        debuff=true},
    [824] = {type="Geo",  effect="Languor",    debuff=true},
    [825] = {type="Geo",  effect="Slow",       debuff=true},
    [826] = {type="Geo",  effect="Paralysis",  debuff=true},
    [827] = {type="Geo",  effect="Gravity",    debuff=true},
}

bubble_jas = {
    [343] = {name="Bolster", dur=210},
    [377] = {name="Wide",    dur=60},
    [346] = {name="LE",      dur=0},
    [347] = {name="EA",      dur=0},
    [350] = {name="BoG",     dur=60},
}

-- these are utf-8 encodings for symbols (courier new supports these)
bubble_ja_symbols = {
    ["Bolster"] = string.char(0xE2,0x98,0xBB),  -- smiling face
    ["LE"]      = string.char(0xE2,0x98,0xBC),  -- empty circle with rays
    ["EA"]      = string.char(0xE2,0x80,0xA2),  -- filled bullet
    ["BoG"]     = string.char(0xE2,0x97,0x8F),  -- filled circle
}

-- colored by element
bubble_text_colors = {
    ["Regen"]      = '\\cs(200,200,200)',
    ["Poison"]     = '\\cs( 50,150,255)',
    ["Refresh"]    = '\\cs(200,200,200)',
    ["Haste"]      = '\\cs( 50,220, 50)',
    ["STR"]        = '\\cs(220, 50, 50)',
    ["DEX"]        = '\\cs(200, 50,200)',
    ["VIT"]        = '\\cs(200,200, 10)',
    ["AGI"]        = '\\cs( 50,220, 50)',
    ["INT"]        = '\\cs( 10,200,200)',
    ["MND"]        = '\\cs( 50,150,255)',
    ["CHR"]        = '\\cs(200,200,200)',
    ["Fury"]       = '\\cs(220, 50, 50)',
    ["Barrier"]    = '\\cs(200,200, 10)',
    ["Acumen"]     = '\\cs( 10,200,200)',
    ["Fend"]       = '\\cs( 50,150,255)',
    ["Precision"]  = '\\cs(200, 50,200)',
    ["Voidance"]   = '\\cs( 50,220, 50)',
    ["Focus"]      = '\\cs(140,140,140)',
    ["Attunement"] = '\\cs(200,200,200)',
    ["Wilt"]       = '\\cs( 50,150,255)',
    ["Frailty"]    = '\\cs( 50,220, 50)',
    ["Fade"]       = '\\cs(220, 50, 50)',
    ["Malaise"]    = '\\cs(200, 50,200)',
    ["Slip"]       = '\\cs(200,200, 10)',
    ["Torpor"]     = '\\cs( 10,200,200)',
    ["Vex"]        = '\\cs(200,200,200)',
    ["Languor"]    = '\\cs(140,140,140)',
    ["Slow"]       = '\\cs(200,200, 10)',
    ["Paralysis"]  = '\\cs( 10,200,200)',
    ["Gravity"]    = '\\cs( 50,220, 50)',
}

-- indicolures may be inferred from PC update and player update packets
-- refer to indinope addon and packets/fields.lua
-- 0x80 bit shows job master stars, 0x20 bit is a flag for widened compass
likely_bubble_id_from_indi_effect = {
    [0x50] = 779,   -- party fire       indi-fury?
    [0x51] = 781,   -- party ice        indi-acumen?
    [0x52] = 771,   -- party wind       indi-haste?
    [0x53] = 780,   -- party earth      indi-barrier?
    [0x54] = 783,   -- party lightning  indi-precision?
    [0x55] = 782,   -- party water      indi-fend?
    [0x56] = 786,   -- party light      indi-attunement?
    [0x57] = 785,   -- party dark       indi-focus?
    [0x58] = 789,   -- enemy fire       indi-fade?
    [0x59] = 792,   -- enemy ice        indi-torpor?
    [0x5A] = 788,   -- enemy wind       indi-frailty?
    [0x5B] = 791,   -- enemy earth      indi-slip?
    [0x5C] = 790,   -- enemy lightning  indi-malaise?
    [0x5D] = 787,   -- enemy water      indi-wilt?
    [0x5E] = 793,   -- enemy light      indi-vex?
    [0x5F] = 794,   -- enemy dark       indi-languor?
}

-- luopan type may be inferred from its model number, if the cast action is missed
-- can't seem to tell if widened compass is active from the mob structure's model info
likely_bubble_id_from_model = {
    [2850] = 809,   -- party fire       geo-fury?
    [2851] = 811,   -- party ice        geo-acumen?
    [2852] = 801,   -- party wind       geo-haste?
    [2853] = 810,   -- party earth      geo-barrier?
    [2854] = 813,   -- party lightning  geo-precision?
    [2855] = 812,   -- party water      geo-fend?
    [2856] = 816,   -- party light      geo-attunement?
    [2857] = 815,   -- party dark       geo-focus?
    [2858] = 819,   -- enemy fire       geo-fade?
    [2859] = 822,   -- enemy ice        geo-torpor?
    [2860] = 818,   -- enemy wind       geo-frailty?
    [2861] = 821,   -- enemy earth      geo-slip?
    [2862] = 820,   -- enemy lightning  geo-malaise?
    [2863] = 817,   -- enemy water      geo-wilt?
    [2864] = 823,   -- enemy light      geo-vex?
    [2865] = 824,   -- enemy dark       geo-languor?
}
