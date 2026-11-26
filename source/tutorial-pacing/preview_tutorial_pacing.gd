extends SceneTree
func _initialize():call_deferred("run")
func snap(name:String):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("user://paced-preview-"+name+".png")
func run():
 var app=load("res://scripts/main.gd").new();app.intro_enabled=false;app.academy.path="user://pacing-preview.cfg";root.add_child(app);await process_frame
 root.size=Vector2i(414,896);app._begin_training("basics",1)
 await create_timer(8).timeout
 assert(app.busy and app.training.phase=="demo")
 await snap("elephant-movement")
 while app.training.phase!="demo_reset":await process_frame
 await snap("elephant-capture")
 while app.training.phase!="practice":await process_frame
 await snap("phone")
 app.training.tap(27);app.training.tap(35)
 while app.busy:await process_frame
 await snap("next-top")
 for dimensions in [Vector2i(320,640),Vector2i(1280,800),Vector2i(896,414)]:
  root.size=dimensions;await create_timer(.3).timeout
  await snap(str(dimensions.x)+"x"+str(dimensions.y))
 app._show_home();app.queue_free();await process_frame
 if FileAccess.file_exists("user://pacing-preview.cfg"):DirAccess.remove_absolute("user://pacing-preview.cfg")
 print("PASS tutorial movement, capture and responsive previews")
 quit()
