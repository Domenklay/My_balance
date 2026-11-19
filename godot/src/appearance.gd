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

static func palette(id: String) -> Dictionary:
    match id:
        "mint":
            return {
                "green":"#21766c", "deep":"#20574f", "ink":"#264b45",
                "muted":"#5c8279", "pale":"#e7f6f1", "accent":"#b7854b",
                "gold":"#fff0d6", "input":"#f9fefc", "border":"#d0e9df",
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
                "muted":"#847768", "pale":"#f5ecd9", "accent":"#ab754a",
                "gold":"#f8e8c8", "input":"#fffcf6", "border":"#e9decb",
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
                "muted":"#acc1b4", "pale":"#253832", "accent":"#e2b980",
                "gold":"#f4dfba", "input":"#253731", "border":"#3d5850",
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
                "muted":"#678376", "pale":"#f2f7f2", "accent":"#bf7e43",
                "gold":"#f8e8c9", "input":"#fbfdfb", "border":"#dfeae1",
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
