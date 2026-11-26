extends SceneTree
func _initialize():call_deferred("run")
func snap(name:String):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("user://piece-readability-"+name+".png")
func run():
 var app=load("res://scripts/main.gd").new();app.intro_enabled=false;root.add_child(app);await process_frame
 root.size=Vector2i(414,896);await process_frame;app._show_home();app._home_play(false);await create_timer(.3).timeout
 assert(app.view_tilt==54 and app.world.get_node("PieceFill").light_cull_mask==2)
 for piece in app.pieces.values():
  for mesh in piece.find_children("*","MeshInstance3D",true,false):assert(mesh.layers==3)
 await snap("phone")
 app._select(12);assert(app.mobile_layout.status.text.contains("Pawn") and app.mobile_layout.status.text.contains("e2"));await snap("selected")
 app._select(-1);assert(app.mobile_layout.status.text.contains("to move"))
 root.size=Vector2i(320,640);await create_timer(.2).timeout;await snap("small")
 root.size=Vector2i(1280,800);await create_timer(.2).timeout;app._view_preset("front");await snap("desktop")
 assert(app.view_tilt==36 and app.game.history.is_empty())
 app.queue_free();await process_frame
 print("PASS piece-only lighting, phone/desktop framing, selected piece identification and unchanged match")
 quit()
