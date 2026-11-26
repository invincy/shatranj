extends SceneTree
func _initialize():call_deferred("run")
func run():
 var app=load("res://scripts/main.gd").new();root.add_child(app)
 await process_frame
 await process_frame
 assert(app.home_active and not app.intro_active)
 app._home_settings();assert(not app.intro_active)
 app._show_home();app._home_play();assert(app.intro_active)
 app._end_intro();assert(not app.home_active and not app.intro_active)
 app._show_home();app._begin_training("basics");assert(not app.intro_active)
 while app.training.phase!="waiting_cue":await process_frame
 assert(not app.training.selected)
 app.training.tap(12);assert(not app.training.selected)
 while app.training.phase!="practice":await process_frame
 assert(app.training.voice.player.get_playback_position()>=12.0)
 for size in [Vector2i(320,640),Vector2i(414,896),Vector2i(896,414),Vector2i(1280,800)]:
  root.size=size;app.training.selected=false
  await process_frame
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("user://guided-select-"+str(size.x)+".png")
  app.training.tap(12)
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("user://guided-move-"+str(size.x)+".png")
 app._show_home();app.queue_free();await process_frame
 print("PASS home opens without intro; Settings and Learn bypass intro; Play runs intro; voice cue gates practice; mobile prompts rendered")
 quit()
