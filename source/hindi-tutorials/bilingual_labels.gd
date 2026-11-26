extends RefCounted
const FONT=preload("res://assets/fonts/NotoSansDevanagari.ttf")
static func bold_font()->FontVariation:
 var font=FontVariation.new();font.base_font=FONT;font.variation_opentype={"wght":700};font.variation_embolden=0.7;return font
static func format_name(value:String)->String:
 var parts=value.split(" (",true,1)
 return "[b]"+parts[0]+"[/b]"+(" ("+parts[1] if parts.size()>1 else "")
static func label(value:String,size:int)->RichTextLabel:
 var label=RichTextLabel.new();label.bbcode_enabled=true;label.fit_content=true;label.scroll_active=false;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 label.add_theme_font_override("normal_font",FONT);label.add_theme_font_override("bold_font",bold_font());label.add_theme_font_size_override("normal_font_size",size);label.add_theme_font_size_override("bold_font_size",size);label.text=format_name(value);return label
