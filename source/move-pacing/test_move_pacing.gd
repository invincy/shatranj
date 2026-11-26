extends SceneTree
func _initialize():call_deferred("run")
func run():
 var app=load("res://scripts/main.gd").new();app.intro_enabled=false;app.academy.path="user://move-pacing-qa.cfg";root.add_child(app);await process_frame
 root.size=Vector2i(414,896);app._begin_training("basics",0);var t=app.training
 while t.phase!="practice":await process_frame
 assert(not t.continue_prompt.visible)
 var start=Time.get_ticks_msec();t.tap(12);t.tap(20)
 await create_timer(.6).timeout;assert(app.busy and not t.continue_prompt.visible)
 while app.busy:await process_frame
 assert(Time.get_ticks_msec()-start>=1500)
 assert(t.complete and t.continue_prompt.visible and t.next_button.visible)
 assert(t.continue_prompt.get_global_rect().end.x<=414 and t.continue_prompt.position.y<140)
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("user://tutorial-next-prompt.png")
 await create_timer(.5).timeout;assert(t.index==0)
 t.continue_prompt.pressed.emit();assert(t.index==1 and not t.continue_prompt.visible)
 app._show_home();app._home_play(false);app.cinematic=false
 start=Time.get_ticks_msec();app._make_move(12,20);await create_timer(.5).timeout;assert(app.busy)
 while app.busy:await process_frame
 assert(Time.get_ticks_msec()-start>=1000)
 app._undo();assert(app.game.history.is_empty())
 app.cinematic=true;start=Time.get_ticks_msec();app._make_move(12,20)
 while app.busy:await process_frame
 assert(Time.get_ticks_msec()-start>=1100)
 app.queue_free();await process_frame
 if FileAccess.file_exists("user://move-pacing-qa.cfg"):DirAccess.remove_absolute("user://move-pacing-qa.cfg")
 print("PASS slower practice and both gameplay modes, completion prompt, explicit Next, reset and undo")
 quit()
