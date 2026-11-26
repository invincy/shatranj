extends Button
var FONT:FontVariation
func _init():
 FONT=FontVariation.new();FONT.base_font=preload("res://assets/fonts/Cinzel.ttf");FONT.variation_opentype={"wght":650}
var caption:=""
var primary:=false
var progress_count:=0
var emblem:Texture2D
func _ready():
 mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 for state in ["normal","hover","pressed","focus","disabled"]:add_theme_stylebox_override(state,StyleBoxEmpty.new())
 mouse_entered.connect(queue_redraw);mouse_exited.connect(queue_redraw);focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw);resized.connect(queue_redraw)
func contour(inset:float)->PackedVector2Array:
 var r=Rect2(Vector2.ONE*inset,size-Vector2.ONE*inset*2);var cut=8.0
 return PackedVector2Array([r.position+Vector2(cut,0),Vector2(r.end.x-cut,r.position.y),Vector2(r.end.x,r.position.y+cut),r.end-Vector2(0,cut),r.end-Vector2(cut,0),Vector2(r.position.x+cut,r.end.y),Vector2(r.position.x,r.end.y-cut),r.position+Vector2(0,cut)])
func _draw():
 var bright=is_hovered() or has_focus()
 draw_colored_polygon(contour(0),Color("382512"))
 draw_colored_polygon(contour(2),Color("f1cf7b") if bright else Color("b79550"))
 draw_colored_polygon(contour(4),Color("543a19") if primary else Color("0b1614"))
 var face=contour(7);var colors=PackedColorArray()
 for point in face:
  colors.append((Color("d0a64f") if primary else Color("294b3b")).lerp(Color("8c571d") if primary else Color("122a23"),point.y/size.y))
 draw_polygon(face,colors)
 # Bevel highlights and inset border remain sharp at every phone resolution.
 var border=contour(9);border.append(border[0]);draw_polyline(border,Color("e9bf67") if primary else Color("72836a"),1,true)
 draw_line(Vector2(16,11),Vector2(size.x-16,11),Color(1,.87,.55,.5),1)
 var font_size=clampi(int(size.x/(13.0 if primary else 9.0)),14,30 if primary else 20)
 var icon_size=32.0 if primary else 23.0
 if emblem:draw_texture_rect(emblem,Rect2(Vector2(18,(size.y-icon_size)*.5),Vector2.ONE*icon_size),false,Color("fff0ba"))
 var left=58.0 if primary else 48.0
 while FONT.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>size.x-left-14 and font_size>10:font_size-=1
 var width=FONT.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
 var x=left+maxf(0,(size.x-left-14-width)*.5)
 var y=size.y*.46 if primary else size.y*.5+font_size*.35
 draw_string(FONT,Vector2(x+1,y+2),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("392719"))
 draw_string(FONT,Vector2(x,y),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("fff0c1"))
 if primary:
  var track=Rect2(Vector2(left,size.y-24),Vector2(size.x-left-22,3))
  draw_rect(track,Color("47391f"));draw_rect(Rect2(track.position,Vector2(track.size.x*progress_count/9.0,3)),Color("ffe3a1"))
  draw_string(ThemeDB.fallback_font,Vector2(left,size.y-32),"Royal Academy",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("fff0c1"))
  draw_string(ThemeDB.fallback_font,Vector2(size.x-48,size.y-32),str(progress_count)+" / 9",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("fff0c1"))
