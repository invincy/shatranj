extends SceneTree
func _initialize():call_deferred("run")
func run():
 var app=load("res://scripts/main.gd").new();app.intro_enabled=false;app.academy.path="user://pacing-test.cfg";root.add_child(app);await process_frame
 root.size=Vector2i(414,896)
 app._show_home();app._begin_training("basics",0)
 var t=app.training
 var match_state=t.saved.game
 for index in range(9):
  if index==7:
   app._show_home();app._begin_training("tactics",7);t=app.training
  elif index>0:t.load_lesson(index)
  var start=Time.get_ticks_msec();var saw_capture=false;var held=false
  assert(t.phase=="demo" and not t.next_button.visible)
  assert(t.top_bar.position.y<20 and t.tutorial_badges.tutorial)
  while t.phase!="practice" and Time.get_ticks_msec()-start<45000:
   await process_frame
   if app.busy:
    assert(app.cinematic and is_equal_approx(app._presentation_speed(),.72))
    if index<6:assert(app.last_move.captured=="p");saw_capture=true
   held=held or t.narration_held
  assert(t.phase=="practice")
  assert(t.motion_elapsed>=2.5)
  assert(not t.narration_held and not t.voice.player.stream_paused)
  assert(t.voice.player.pitch_scale==1.0)
  assert(app.game.fen()==t.Lessons.LESSONS[index].fen and app.game.history.is_empty())
  assert(not app.cinematic and app._presentation_speed()==1.0)
  assert(app.academy.completed.is_empty())
  if index<6:assert(saw_capture)
  print("PASS lesson ",index," movement_seconds=",snappedf(t.motion_elapsed,.1)," narration_held=",held)
  if index in [0,1,4]:
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("user://tutorial-paced-"+str(index)+".png")
 t.tap(18);t.tap(35)
 while app.busy:await process_frame
 assert(t.next_button.visible and t.next_button.get_global_rect().position.y<60)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("user://tutorial-paced-complete.png")
 app._show_home();assert(app.game==match_state and not app.busy)
 app._begin_training("basics",1);await create_timer(7).timeout;app._show_home()
 assert(app.game==match_state and not app.busy)
 await create_timer(2).timeout
 assert(app.game==match_state and not app.busy and app._presentation_speed()==1.0)
 app.queue_free();await process_frame
 if FileAccess.file_exists("user://pacing-test.cfg"):DirAccess.remove_absolute("user://pacing-test.cfg")
 print("PASS all slow demonstrations, capture examples, narration pitch/gate, top Next, restored practice, no demo XP and interrupted capture")
 quit()
