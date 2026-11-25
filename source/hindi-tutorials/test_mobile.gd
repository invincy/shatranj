extends SceneTree
var failures:=0
func check(ok:bool,title:String):
 if ok:print("PASS ",title)
 else:failures+=1;push_error(title)
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(414,896)
 var app=load("res://scripts/main.gd").new();app.intro_enabled=false;root.add_child(app);await process_frame;await process_frame
 app._show_home();app._home_play();await process_frame
 check(app.mobile_layout.compact and not app.ui_side.visible,"phone opens with drawer closed")
 check(app.board_container.size.x==414 and app.camera.keep_aspect==Camera3D.KEEP_WIDTH,"portrait board fits full width")
 app.mobile_layout.toggle();check(app.ui_side.visible and app.ui_side.position.x>=0,"controls drawer opens inside screen")
 app.mobile_layout.toggle();check(not app.ui_side.visible,"drawer closes")
 var original=app.game
 app._begin_training("basics");await process_frame
 check(app.training.panel.position.y>=app.board_container.size.y,"portrait lesson is below board")
 while app.training.phase!="practice":await process_frame
 var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
 click.position=app.camera.unproject_position(app._square_pos(12))*app.board_container.size/Vector2(app.viewport.size)
 app._board_input(click);check(app.training.selected,"portrait board touch projection selects pawn")
 root.size=Vector2i(896,414);await process_frame;await process_frame
 check(app.training.panel.position.x>=app.board_container.size.x,"landscape lesson moves beside board")
 app._show_home();app._home_play();check(app.game==original,"rotation and lessons preserve match")
 root.size=Vector2i(320,640);await process_frame;await process_frame
 check(app.mobile_layout.bar.size.x<=300,"small phone toolbar fits")
 root.size=Vector2i(1280,800);await process_frame;await process_frame
 check(not app.mobile_layout.compact and app.ui_side.visible and app.ui_top.visible,"desktop sidebar restored on resize")
 app.queue_free();await create_timer(.2).timeout
 print("MOBILE_TESTS_COMPLETE failures=",failures);quit(failures)
