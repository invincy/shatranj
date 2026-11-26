extends SceneTree
func _initialize():call_deferred("run")
func run():
 var app=load("res://scripts/main.gd").new();app.intro_enabled=false;app.academy.path="user://portrait-alignment-qa.cfg";root.add_child(app);await process_frame
 root.size=Vector2i(414,896);app._begin_training("basics",0);var t=app.training
 t.lesson_serial+=1;t.phase="practice";t.voice.stop();t.stop_camera()
 for piece in ["P","R","B","N","Q","K"]:
  t.portrait_view.show_piece(piece,12);await create_timer(.25).timeout
  var view=t.portrait_view
  var foot=view.camera.unproject_position(Vector3(0,.038,0))
  assert(absf(view.position.y+foot.y-t.panel.position.y)<2.0)
  await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("user://aligned-portrait-"+piece+".png")
 root.size=Vector2i(320,640);await create_timer(.2).timeout
 var foot=t.portrait_view.camera.unproject_position(Vector3(0,.038,0))
 assert(absf(t.portrait_view.position.y+foot.y-t.panel.position.y)<2.0)
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("user://aligned-portrait-small.png")
 app.queue_free();await process_frame
 print("PASS all six preview ground lines align with panel edge, including small phone")
 quit()
