extends RefCounted

# All values are dynamic so the UI, graph, modal cards and navigation change
# together. Keep high contrast for dark cards rather than simply inverting RGB.
const NAMES = {
    "forest": "Лесная светлая",
    "mint": "Мятная нежность",
    "sand": "Тёплый беж",
    "dark": "Тёмная лесная"
}
const ORDER = ["forest", "mint", "sand", "dark"]

static func is_valid_theme(id: String) -> bool:
    return NAMES.has(id)

static func name_for(id: String) -> String:
    return str(NAMES.get(id, NAMES["forest"]))

# High contrast is optional and independent of the chosen theme.
# Every theme keeps its signature colors and ornament, but improves separation
# of background, cards, fields, buttons, subtle text and graph annotations.
const HIGH_OVERRIDES = {
    "forest": {
        "green":"#12513d", "deep":"#0a382b", "ink":"#162f25",
        "muted":"#3d5548", "border":"#8caa98", "secondary":"#d5e8d9",
        "background":"#dcebe1", "surface":"#ffffff", "tint":"#cce5d4",
        "row":"#e6f2e8", "input":"#ffffff", "header":"#0a382b",
        "head_muted":"#e6f6eb", "hero":"#0a382b", "hero_muted":"#e7f4e8",
        "chip":"#18543e", "track":"#477e60", "fill":"#e1f3a6",
        "text_accent":"#12513d", "grid":"#9dbca9", "area":"#b7d9c4"
    },
    "mint": {
        "green":"#126354", "deep":"#103f36", "ink":"#123c34",
        "muted":"#3a5b51", "border":"#88b6a7", "secondary":"#c9e8dc",
        "background":"#d6efe5", "surface":"#ffffff", "tint":"#bde3d2",
        "row":"#e3f5ec", "input":"#ffffff", "header":"#103f36",
        "head_muted":"#e2fff1", "hero":"#10483d", "hero_muted":"#e2fff1",
        "chip":"#1b5e4d", "track":"#367c64", "fill":"#cbf1c9",
        "text_accent":"#125c4b", "grid":"#9bc7b4", "area":"#bae5ce"
    },
    "sand": {
        "green":"#514b2d", "deep":"#443a2b", "ink":"#292419",
        "muted":"#5c5140", "border":"#baa98e", "secondary":"#e3d5bd",
        "background":"#ede1cd", "surface":"#fffdf6", "tint":"#dfcba9",
        "row":"#f6e9d3", "input":"#fffdf8", "header":"#443a2b",
        "head_muted":"#fff3db", "hero":"#51462f", "hero_muted":"#fff0d4",
        "chip":"#665538", "track":"#88724d", "fill":"#f9e5ab",
        "text_accent":"#514b2d", "grid":"#c3ac8d", "area":"#e5cfab"
    },
    "dark": {
        "green":"#30745d", "deep":"#091711", "ink":"#ffffff",
        "muted":"#d1e2d7", "border":"#738d7c", "secondary":"#2b4a3b",
        "background":"#091410", "surface":"#1b3024", "tint":"#254331",
        "row":"#2d4837", "input":"#233b2d", "header":"#091711",
        "head_muted":"#e2f6e6", "hero":"#173c29", "hero_muted":"#e4f8e9",
        "chip":"#24523a", "track":"#47795e", "fill":"#e1f4b1",
        "text_accent":"#b7f4c6", "grid":"#668472", "area":"#2d563d"
    }
}

static func palette(id: String, high_contrast: bool = false) -> Dictionary:
    var base: Dictionary = _base_palette(id)
    if high_contrast:
        var overrides: Dictionary = HIGH_OVERRIDES.get(id, HIGH_OVERRIDES["forest"])
        for key in overrides:
            base[key] = overrides[key]
    return base

static func _base_palette(id: String) -> Dictionary:
    match id:
        "mint":
            return {
                "green":"#21766c", "deep":"#20574f", "ink":"#264b45",
                "muted":"#4c7167", "pale":"#e7f6f1", "accent":"#b7854b",
                "gold":"#fff0d6", "input":"#f9fefc", "border":"#bad9cc",
                "secondary":"#d7eee6", "background":"#e9f8f3",
                "surface":"#ffffff", "tint":"#dbf3e9", "row":"#eefaf5",
                "header":"#20574f", "head_muted":"#c9ece0", "icon":"#2a7065",
                "hero":"#23665c", "hero_muted":"#d2eee4", "chip":"#30786e",
                "track":"#3e8479", "fill":"#d7f4dc",
                "text_accent":"#21766c", "protein":"#d7f8e4",
                "fat":"#ffdea9", "carbs":"#d7e7ff", "grid":"#d7e8df",
                "area":"#dff3e8", "pattern":"dots", "pattern_color":"#58a995",
                "logo_text":"#fff0d6"
            }
        "sand":
            return {
                "green":"#646b47", "deep":"#635a47", "ink":"#443d35",
                "muted":"#685e51", "pale":"#f5ecd9", "accent":"#ab754a",
                "gold":"#f8e8c8", "input":"#fffcf6", "border":"#d8c7ad",
                "secondary":"#eee6d6", "background":"#f8f2e7",
                "surface":"#fffdf8", "tint":"#f1e7d6", "row":"#f8f1e5",
                "header":"#635a47", "head_muted":"#f5e7d0", "icon":"#7b6e55",
                "hero":"#696448", "hero_muted":"#f6edd8", "chip":"#7a7558",
                "track":"#92896b", "fill":"#f2dfac",
                "text_accent":"#646b47", "protein":"#d9edc9",
                "fat":"#ffddae", "carbs":"#e4e4ff", "grid":"#e9dfd3",
                "area":"#f2e8d4", "pattern":"grid", "pattern_color":"#b39e7d",
                "logo_text":"#ffedcd"
            }
        "dark":
            return {
                "green":"#367964", "deep":"#122923", "ink":"#eef5ef",
                "muted":"#bfd6c6", "pale":"#253832", "accent":"#e2b980",
                "gold":"#f4dfba", "input":"#253731", "border":"#587364",
                "secondary":"#30473e", "background":"#101b1a",
                "surface":"#1b2c27", "tint":"#23372f", "row":"#283c35",
                "header":"#122923", "head_muted":"#b6d9c5", "icon":"#2b493c",
                "hero":"#274c3e", "hero_muted":"#d0e7d8", "chip":"#315b4c",
                "track":"#416e5a", "fill":"#cce7b4",
                "text_accent":"#a5e4c0", "protein":"#dbf5d5",
                "fat":"#f4dba7", "carbs":"#d3e6ff", "grid":"#3a554a",
                "area":"#263f34", "pattern":"stars", "pattern_color":"#92caaa",
                "logo_text":"#f4dfba"
            }
        _:
            return {
                "green":"#195b4a", "deep":"#123f36", "ink":"#263a32",
                "muted":"#526e5d", "pale":"#f2f7f2", "accent":"#bf7e43",
                "gold":"#f8e8c9", "input":"#fbfdfb", "border":"#cadbcd",
                "secondary":"#e8f3e9", "background":"#f0f6f1",
                "surface":"#ffffff", "tint":"#eaf5e9", "row":"#f4f9f4",
                "header":"#123f36", "head_muted":"#c8e4d4", "icon":"#2e7160",
                "hero":"#123f36", "hero_muted":"#d5e7d9", "chip":"#286453",
                "track":"#3d7967", "fill":"#deebbd",
                "text_accent":"#195b4a", "protein":"#d7f4d7",
                "fat":"#f2d49d", "carbs":"#d3e5fa", "grid":"#e2ece5",
                "area":"#dcefe4", "pattern":"leaves", "pattern_color":"#6da48b",
                "logo_text":"#f8e8c9"
            }
