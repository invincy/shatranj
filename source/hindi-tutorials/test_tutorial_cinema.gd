extends SceneTree
func _initialize():call_deferred("run")
func run():
 var app=load("res://scripts/main.gd").new();app.intro_enabled=false;app.academy.path="user://cinema-qa.cfg";root.add_child(app);await process_frame
 root.size=Vector2i(414,896)
 app._begin_training("basics",1)
 var original=app.training.saved.game
 for index in [1,2,3]:
  app.training.load_lesson(index)
  await create_timer(1.6).timeout
  assert(app.training.shot_active and not app.camera.position.is_equal_approx(app.board_camera))
  print("PORTRAIT_ANIMATIONS ",index," ",app._animation_player(app.training.portrait_view.model).get_animation_list())
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("user://cinema-side-"+str(index)+".png")
  var deadline=Time.get_ticks_msec()+30000
  while app.training.phase!="practice" and Time.get_ticks_msec()<deadline:await process_frame
  assert(app.training.phase=="practice" and not app.training.shot_active)
  assert(app.camera.position.is_equal_approx(app.board_camera))
  assert(app.game.history.is_empty() and app.academy.completed.is_empty())
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("user://cinema-board-"+str(index)+".png")
 assert("elephant_call" in app.sound.events and "camel_call" in app.sound.events and "horse_call" in app.sound.events)
 app.training.load_lesson(0);await create_timer(1).timeout;app._show_home()
 assert(not app.busy and app.game==original)
 await create_timer(2).timeout
 assert(app.home_active and app.game==original)
 app.queue_free();await process_frame
 print("PASS animal portraits, cinematic camera, calls, board return, cue gating, no demo XP and mid-shot exit")
 quit()
