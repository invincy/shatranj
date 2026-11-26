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
 if is_instance_valid(training) and training.index==7 and training.phase in ["demo","practice"]:
  draw_pin()
 if not is_instance_valid(training) or training.phase!="practice" or training.app.busy:return
 var app=training.app
 var lesson=training.Lessons.LESSONS[training.index]
 var square:int=lesson.from
 var caption="Tap "+app.Rules.square_name(square)+" · select piece"
 var color=Color("ffe19a")
 if training.selected:
  color=Color("9ff1bf")
  for move in app.game.legal_moves(lesson.from):
   if lesson.targets.is_empty() or move.to in lesson.targets:outline(move.to,Color("ffb09c") if app.game.board[move.to]!="" else color)
  caption="Choose a highlighted square"
 else:
  outline(square,color)
  var point=project(square,Vector3(0,.1,0))
  var tile_width=project(square,Vector3(.45,0,0)).distance_to(project(square,Vector3(-.45,0,0)))
  var pulse=clampf(tile_width*.5,10,22)+1.5*sin(Time.get_ticks_msec()*.003)
  draw_arc(point,pulse,0,TAU,48,color,2.0,true)
 # A compact prompt at the board edge, never over the piece's head/body.
 var font=ThemeDB.fallback_font
 var bounds=app.board_container.get_global_rect()
 var font_size=14
 var text_size=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
 var box_size=text_size+Vector2(20,14)
 var at=Vector2(bounds.get_center().x-box_size.x*.5,bounds.position.y+8)
 draw_style_box(panel_style(color),Rect2(at,box_size))
 draw_string(font,at+Vector2(10,20),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func panel_style(color:Color)->StyleBoxFlat:
 var style=StyleBoxFlat.new();style.bg_color=Color("0b191eee");style.border_color=color;style.set_border_width_all(1);style.set_corner_radius_all(8);return style

func draw_pin():
 var red=Color(1,.4,.3,.8)
 var gold=Color(1,.82,.4,.8)
 var enemy=project(60,Vector3(0,.09,0))
 var shield=project(12,Vector3(0,.09,0))
 var king=project(4,Vector3(0,.09,0))
 var exposed=training.pin_stage=="exposed"
 if training.pin_stage=="capture":
  draw_line(shield,enemy,gold,3,true);outline(60,gold);outline(4,gold);return
 draw_line(enemy,king if exposed else shield,red,3,true)
 outline(60,red);outline(4,red if exposed else gold)
 if not exposed:
  draw_line(shield,king,gold,2,true)
  outline(12,gold)
 else:
  var sideways=project(11,Vector3(0,.09,0))
  draw_line(shield,sideways,red,2,true)
  draw_line(sideways-Vector2(7,7),sideways+Vector2(7,7),red,3,true)
  draw_line(sideways+Vector2(-7,7),sideways+Vector2(7,-7),red,3,true)
