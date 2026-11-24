extends RefCounted

# All values are dynamic so the UI, graph, modal cards and navigation change
# together. Keep high contrast for dark cards rather than simply inverting RGB.
const NAMES = {
    "forest": "Лесная светлая",
    "mint": "Мятная нежность",
    "sand": "Тёплый беж",
    "dark": "Ночной синий",
    "botanical": "Сливовый уют"
}
const ORDER = ["forest", "mint", "sand", "dark", "botanical"]

static func is_valid_theme(id: String) -> bool:
    return NAMES.has(id)

static func name_for(id: String) -> String:
    return str(NAMES.get(id, NAMES["forest"]))

# High contrast is optional and independent of the chosen theme.
# Every theme keeps its signature colors and ornament, but improves separation
# of background, cards, fields, buttons, subtle text and graph annotations.
const HIGH_OVERRIDES = {
    "botanical": {
        "green":"#075A42", "deep":"#053A2B", "ink":"#102E25",
        "muted":"#345444", "border":"#779E87", "secondary":"#DCEEE1",
        "background":"#EDF3E9", "surface":"#FFFEFA", "tint":"#E0F2E4",
        "row":"#E7F3EB", "input":"#FFFFFF", "header":"#04382C",
        "head_muted":"#EDFFE9", "hero":"#043A2E", "hero_muted":"#E9FFEB",
        "chip":"#195845", "track":"#6C9C8B", "fill":"#E7F6A8",
        "text_accent":"#075C43", "grid":"#8EB49A", "area":"#BFDEC7"
    },
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

# A richer, themed color system: neutral surfaces, contrasting section cards,
# and distinctly colored nutrition tiles. Kept separate from contrast settings.
# Each complete palette overrides the historical base tokens. Stored theme ids
# intentionally remain unchanged so users keep their selected theme on update.
const COLOR_VARIANTS = {
    "forest": {"protein_bg": "#D9F2DE", "fat_bg": "#FFE4B9", "carbs_bg": "#E4E1FB", "protein_text": "#235D3A", "fat_text": "#865521", "carbs_text": "#4B4880", "gold": "#FAE6C6", "logo_text": "#F9E7CB", "protein": "#D9F2DE", "fat": "#FFE4B9", "carbs": "#E4E1FB", "green": "#195C47", "deep": "#124232", "ink": "#203B30", "muted": "#50675A", "pale": "#EEF6EE", "accent": "#B78249", "input": "#FFFFFF", "border": "#BCD2C2", "secondary": "#E0EFE5", "background": "#F3F7F1", "surface": "#FFFFFF", "tint": "#E9F3E8", "row": "#F1F7F0", "header": "#153E30", "head_muted": "#DDF0E2", "icon": "#2D7054", "hero": "#194B38", "hero_muted": "#E9F6E9", "chip": "#27624A", "track": "#48816A", "fill": "#D9EDB6", "text_accent": "#195C47", "grid": "#C9DED1", "area": "#DFEEE0", "pattern": "leaves", "pattern_color": "#73A489", "nav_bg": "#F3F7F1", "overview": "#F8F4EC", "activity": "#E9F1E9", "tile": "#EDF5EA", "nav_active": "#195C47", "activity_text": "#35674B"},
    "mint": {"protein_bg": "#DDF5E9", "fat_bg": "#FFE5D7", "carbs_bg": "#E3E7FB", "protein_text": "#22664D", "fat_text": "#86512D", "carbs_text": "#4D5491", "gold": "#FAE6C6", "logo_text": "#F9E7CB", "protein": "#D9F2DE", "fat": "#FFE4B9", "carbs": "#E4E1FB", "green": "#116F8A", "deep": "#075267", "ink": "#173F50", "muted": "#4E6C77", "pale": "#EAF8FB", "accent": "#C57F63", "input": "#FFFFFF", "border": "#A7D0DC", "secondary": "#D5F0F5", "background": "#EDF9FB", "surface": "#FFFFFF", "tint": "#E0F4F8", "row": "#EAF6FA", "header": "#13556C", "head_muted": "#DAF3F9", "icon": "#1B7A93", "hero": "#126882", "hero_muted": "#E2F8FC", "chip": "#26768D", "track": "#58A1B2", "fill": "#CBE9EF", "text_accent": "#126C84", "grid": "#C7E7EC", "area": "#D7EFF4", "pattern": "dots", "pattern_color": "#7CB9CD", "nav_bg": "#EDF9FB", "overview": "#F5F9FF", "activity": "#DFF1F7", "tile": "#E8F4FA", "nav_active": "#116F8A", "activity_text": "#246D84"},
    "sand": {"protein_bg": "#E5F0DA", "fat_bg": "#FDE3C4", "carbs_bg": "#EFE4F4", "protein_text": "#49653B", "fat_text": "#8B572D", "carbs_text": "#70557D", "gold": "#FAE6C6", "logo_text": "#F9E7CB", "protein": "#D9F2DE", "fat": "#FFE4B9", "carbs": "#E4E1FB", "green": "#98603D", "deep": "#674128", "ink": "#4A3426", "muted": "#796456", "pale": "#FBF2E6", "accent": "#C48058", "input": "#FFFCF7", "border": "#DEC7AD", "secondary": "#F2E3D0", "background": "#FCF7EF", "surface": "#FFFEFA", "tint": "#F5E9D9", "row": "#F8F0E5", "header": "#795236", "head_muted": "#FFF1D9", "icon": "#9C714A", "hero": "#8C5C3B", "hero_muted": "#FFF1DE", "chip": "#A27251", "track": "#B58C6C", "fill": "#F6DDA9", "text_accent": "#915B37", "grid": "#ECDCC9", "area": "#F2E1CB", "pattern": "grid", "pattern_color": "#BC9E7B", "nav_bg": "#FCF7EF", "overview": "#FFF9EA", "activity": "#F4E9DB", "tile": "#F8EDDE", "nav_active": "#94603C", "activity_text": "#845536"},
    "dark": {"protein_bg": "#224D55", "fat_bg": "#624B45", "carbs_bg": "#3C4576", "protein_text": "#C4F2E4", "fat_text": "#FBE0BF", "carbs_text": "#D4DCFC", "gold": "#F6E2C7", "logo_text": "#F6DABA", "protein": "#D9F2DE", "fat": "#FFE4B9", "carbs": "#E4E1FB", "green": "#477EB5", "deep": "#13273F", "ink": "#F3F7FF", "muted": "#BCCBDE", "pale": "#263D56", "accent": "#E5B57B", "input": "#304863", "border": "#45617B", "secondary": "#253C56", "background": "#101B2B", "surface": "#192B44", "tint": "#233A53", "row": "#283D57", "header": "#101E31", "head_muted": "#D8E6F4", "icon": "#31577A", "hero": "#223D5D", "hero_muted": "#E3EFFA", "chip": "#31557A", "track": "#507EAA", "fill": "#C6E1F7", "text_accent": "#C5E4FF", "grid": "#4F6681", "area": "#2F4C69", "pattern": "stars", "pattern_color": "#7298C4", "nav_bg": "#172538", "overview": "#263950", "activity": "#2B405A", "tile": "#304A65", "nav_active": "#477EB5", "activity_text": "#D7E8FA"},
    "botanical": {"protein_bg": "#374957", "fat_bg": "#634350", "carbs_bg": "#514569", "protein_text": "#CDF0E6", "fat_text": "#FFE0CC", "carbs_text": "#E7D4FB", "gold": "#F6DFE9", "logo_text": "#F9E2F1", "protein": "#D9F2DE", "fat": "#FFE4B9", "carbs": "#E4E1FB", "green": "#7F4D77", "deep": "#3C243F", "ink": "#F9F1F8", "muted": "#DBC8DA", "pale": "#46354D", "accent": "#E6ABC4", "input": "#423249", "border": "#806589", "secondary": "#513B59", "background": "#241C2A", "surface": "#34283B", "tint": "#403048", "row": "#46344D", "header": "#2B2031", "head_muted": "#F2DCEB", "icon": "#6E486E", "hero": "#543456", "hero_muted": "#F2DAEE", "chip": "#724B76", "track": "#A678A7", "fill": "#EAC7DE", "text_accent": "#F2C7E2", "grid": "#765D7E", "area": "#533D5C", "pattern": "botanical", "pattern_color": "#BB91B7", "nav_bg": "#2C2232", "overview": "#3D2E44", "activity": "#4A3650", "tile": "#513F59", "nav_active": "#86537F", "activity_text": "#F4E5F2"}
}

# High contrast preserves each theme's own hue (not a shared green tint).
const COLOR_HIGH_ADJUSTMENTS = {
    "forest": {"background": "#E7F0E7", "border": "#769D84", "secondary": "#D4E7D8", "activity": "#DCEADC", "tint": "#D8EBDB", "nav_active": "#0E4B36"},
    "mint": {"background": "#DFEFF5", "border": "#5D9FB5", "secondary": "#C6E6ED", "activity": "#CEEAF2", "tint": "#CFEAEF", "nav_active": "#075A74"},
    "sand": {"background": "#F3E7D7", "border": "#AF8E71", "secondary": "#EAD8C4", "activity": "#EADAC6", "tint": "#F1DFC9", "nav_active": "#79472B"},
    "dark": {"background": "#0B1421", "border": "#97ADC5", "secondary": "#314E6E", "activity": "#354C68", "tint": "#2B405B", "nav_active": "#5188B9"},
    "botanical": {"background": "#1D1523", "border": "#AE88AD", "secondary": "#654A6B", "activity": "#58415D", "tint": "#4A3652", "nav_active": "#A467A0"}
}

static func palette(id: String, high_contrast: bool = false) -> Dictionary:
    var base: Dictionary = _base_palette(id)
    if high_contrast:
        var overrides: Dictionary = HIGH_OVERRIDES.get(id, HIGH_OVERRIDES["forest"])
        for key in overrides:
            base[key] = overrides[key]
    var colors: Dictionary = COLOR_VARIANTS.get(id, COLOR_VARIANTS["forest"])
    for key in colors:
        base[key] = colors[key]
    if high_contrast:
        var contrast_colors: Dictionary = COLOR_HIGH_ADJUSTMENTS.get(id, COLOR_HIGH_ADJUSTMENTS["forest"])
        for key in contrast_colors:
            base[key] = contrast_colors[key]
    return base

static func _base_palette(id: String) -> Dictionary:
    match id:
        "botanical":
            return {
                "green":"#0B644B", "deep":"#064633", "ink":"#173D2F",
                "muted":"#4F6D59", "pale":"#EEF6E9", "accent":"#E29B42",
                "gold":"#F8E7B0", "input":"#FFFEFA", "border":"#A7C4B0",
                "secondary":"#E5F1E6", "background":"#F0F4ED",
                "surface":"#FFFEFA", "tint":"#E7F5EA", "row":"#F4F5EA",
                "header":"#063E31", "head_muted":"#D2EDDA", "icon":"#195F4C",
                "hero":"#073F33", "hero_muted":"#E3F4E9", "chip":"#185740",
                "track":"#4E8874", "fill":"#E9F2A6",
                "text_accent":"#0A624B", "protein":"#D8F2DD",
                "fat":"#FFE5B5", "carbs":"#E1DFFB", "grid":"#C9DDCB",
                "area":"#D5E8D8", "pattern":"botanical",
                "pattern_color":"#6B9E64", "logo_text":"#FFF0BF",
                "nav_bg":"#F9F6EC"
            }
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
