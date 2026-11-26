extends Control
var training
var icons:Dictionary={}
func _ready():
 for role in ["p","r","b","n","q","k"]:icons[role]=load("res://assets/icons/"+role+".svg")
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _process(_delta):queue_redraw()
func project(square:int,offset:=Vector3.ZERO)->Vector2:
 var app=training.app
 return app.board_container.position+app.camera.unproject_position(app._square_pos(square)+offset)*app.board_container.size/Vector2(app.viewport.size)
func outline(square:int,color:Color):
 var points=PackedVector2Array()
 for offset in [Vector3(-.46,.08,-.46),Vector3(.46,.08,-.46),Vector3(.46,.08,.46),Vector3(-.46,.08,.46),Vector3(-.46,.08,-.46)]:points.append(project(square,offset))
 draw_polyline(points,color,3.0,true)
func _draw():
 if not is_instance_valid(training) or training.phase in ["complete","leaving"] or training.app.busy or training.shot_active:return
 var app=training.app
 var lesson=training.Lessons.LESSONS[training.index]
 var square:int=lesson.from
 var practice:bool=training.phase=="practice"
 var caption="Watch this piece"
 var color=Color("ffe19a")
 if practice:
  caption="Tap "+app.Rules.square_name(square)+" · select piece"
  if training.selected:
   color=Color("9ff1bf")
   var moves=app.game.legal_moves(lesson.from)
   for move in moves:
    if lesson.targets.is_empty() or move.to in lesson.targets:outline(move.to,Color("ffb09c") if app.game.board[move.to]!="" else color)
   square=training.DEMO_TARGETS[training.index]
   caption="Tap a highlighted square"
   if not lesson.targets.is_empty():caption="Tap "+("g1 or c1" if training.index==6 else ("e3, e4 or d3" if training.index==0 else app.Rules.square_name(square)))
 elif training.phase=="demo_reset":return
 outline(square,color)
 var point=project(square,Vector3(0,.1,0))
 var pulse=22.0+3.0*sin(Time.get_ticks_msec()*.006)
 draw_arc(point,pulse,0,TAU,48,color,3.0,true)
 var role:String=["p","r","b","n","q","k","k","r","n"][training.index]
 var badge=point+Vector2(0,34)
 draw_circle(badge,16,Color("102326d9"));draw_arc(badge,16,0,TAU,32,color,1.5,true)
 draw_texture_rect(icons[role],Rect2(badge-Vector2(11,11),Vector2(22,22)),false,color)
 var font=ThemeDB.fallback_font
 var text_size=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,16)
 var bounds=app.board_container.get_global_rect()
 var box_size=text_size+Vector2(20,16)
 var at=Vector2(clampf(point.x-box_size.x*.5,bounds.position.x+8,bounds.end.x-box_size.x-8),clampf(point.y-82,bounds.position.y+8,bounds.end.y-box_size.y-8))
 draw_line(at+Vector2(box_size.x*.5,box_size.y),point-Vector2(0,22),color,2,true)
 draw_style_box(panel_style(color),Rect2(at,box_size))
 draw_string(font,at+Vector2(10,23),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,16,color)
func panel_style(color:Color)->StyleBoxFlat:
 var style=StyleBoxFlat.new();style.bg_color=Color("0b191eee");style.border_color=color;style.set_border_width_all(1);style.set_corner_radius_all(8);return style
