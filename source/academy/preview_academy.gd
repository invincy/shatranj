extends SceneTree
func _initialize():call_deferred("run")
func run():
 var Store=load("res://scripts/academy_progress.gd")
 var store=Store.new();store.path="user://academy-qa.cfg"
 store.finish(0);store.finish(0);assert(store.xp()==25)
 var restored=Store.new();restored.path=store.path;restored.load_progress();assert(restored.completed.has(0) and restored.next_lesson()==1)
 for index in range(1,9):restored.finish(index)
 assert(restored.xp()==225 and restored.next_lesson()==0)
 var app=load("res://scripts/main.gd").new();app.academy.path="user://academy-ui-qa.cfg";root.add_child(app)
 await process_frame
 await process_frame
 app.academy.completed.clear();app._show_home()
 for size in [Vector2i(1280,800),Vector2i(414,896),Vector2i(320,640),Vector2i(896,414)]:
  root.size=size;app.home_menu.show_home()
  await process_frame
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("user://academy-home-"+str(size.x)+".png")
 root.size=Vector2i(414,896);app.home_menu.show_learn()
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("user://academy-journey.png")
 app.academy.finish(0);app.home_menu.continue_learning();assert(app.training.index==1)
 assert(app.academy.completed.size()==1)
 while app.training.phase!="practice":await process_frame
 assert(app.academy.xp()==25)
 app.training.tap(27);app.training.tap(51)
 while app.busy:await process_frame
 assert(app.academy.xp()==50)
 var persisted=Store.new();persisted.path=app.academy.path;persisted.load_progress();assert(persisted.completed.has(1))
 app._show_home();app.home_menu.show_progress()
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("user://academy-progress.png")
 app.queue_free();await create_timer(2).timeout
 DirAccess.remove_absolute("user://academy-qa.cfg");DirAccess.remove_absolute("user://academy-ui-qa.cfg")
 print("PASS progress reload, unique XP, next lesson, journey routing and responsive academy screens")
 quit()
