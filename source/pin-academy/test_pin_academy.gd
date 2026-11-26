extends SceneTree
func _initialize():call_deferred("run")
func snap(name:String):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("user://pin-academy-"+name+".png")
func run():
 var app=load("res://scripts/main.gd").new();app.intro_enabled=false;app.academy.path="user://pin-academy-qa.cfg";root.add_child(app);await process_frame
 root.size=Vector2i(414,896)
 app.academy.completed={0:true,1:true}
 app._show_home();var menu=app.home_menu
 menu.action_buttons[0].pressed.emit()
 assert(menu.screen=="learn" and app.home_active and not is_instance_valid(app.training))
 var ids=[]
 for button in menu.action_buttons:
  if button.has_meta("lesson_index"):ids.append(button.get_meta("lesson_index"))
 assert(ids==[0,1,2,3,4,5,6,7,8])
 await snap("lesson-list")
 menu.action_buttons[0].pressed.emit()
 assert(app.training.index==2)
 app._show_academy();assert(menu.screen=="learn" and app.home_active)
 var original=app.game
 menu.open_lesson(7);var t=app.training;var fen:String=app.game.fen()
 assert(not app.game.in_check("w"))
 for move in app.game.legal_moves(12):assert(move.to%8==4)
 var hypothetical=app.Rules.new(fen);hypothetical.board[12]="";hypothetical.board[11]="R"
 assert(hypothetical.in_check("w"))
 await create_timer(6.0).timeout
 assert(t.pin_stage=="exposed" and app.game.fen()==fen and app.game.history.is_empty())
 assert(app.pieces[12].position.distance_to(app._square_pos(11))<.01)
 await snap("exposed")
 var deadline=Time.get_ticks_msec()+40000
 while t.phase!="practice" and Time.get_ticks_msec()<deadline:await process_frame
 assert(t.phase=="practice" and app.game.fen()==fen and not t.voice.player.stream_paused)
 assert(app.academy.completed.size()==2)
 await snap("practice")
 t.tap(12);t.tap(11);assert(app.game.fen()==fen and not app.busy)
 t.tap(60)
 while app.busy:await process_frame
 assert(t.complete and app.game.board[60]=="R" and not app.game.in_check("w"))
 assert(t.next_button.visible and t.next_button.get_global_rect().position.y<60)
 app._show_academy();assert(app.game==original and menu.screen=="learn")
 menu.open_lesson(7);await create_timer(4.8).timeout;app._show_academy();await create_timer(2).timeout
 assert(app.game==original and not app.busy and menu.screen=="learn")
 app.queue_free();await process_frame
 if FileAccess.file_exists("user://pin-academy-qa.cfg"):DirAccess.remove_absolute("user://pin-academy-qa.cfg")
 print("PASS academy entry/list/continue, pin shield and illegal-sideways illustration, unchanged rules, legal escape, top Next, mid-illustration exit and saved match")
 quit()
