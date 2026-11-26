extends SceneTree
func _initialize():call_deferred("run")
func snap(name:String):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("user://royal-title-"+name+".png")
func run():
 var app=load("res://scripts/main.gd").new();app.intro_enabled=false;app.academy.path="user://title-test.cfg";root.add_child(app);await process_frame
 app._show_home();var menu=app.home_menu
 for dimensions in [Vector2i(414,896),Vector2i(320,640),Vector2i(896,414),Vector2i(1280,800)]:
  root.size=dimensions;await create_timer(.5).timeout
  assert(menu.hero_controls.position.y>=dimensions.y*.5)
  for button in menu.action_buttons:
   assert(button.get_global_rect().end.x<=dimensions.x and button.get_global_rect().end.y<=dimensions.y)
  await snap(str(dimensions.x)+"x"+str(dimensions.y))
 var old_position=app.camera.position;await create_timer(1).timeout;assert(old_position.distance_to(app.camera.position)>.001)
 menu.action_buttons[0].pressed.emit();assert(menu.screen=="learn" and not menu.hero.visible and menu.scroll.visible)
 var lessons=0
 for button in menu.action_buttons:
  if button.has_meta("lesson_index"):lessons+=1
 assert(lessons==9)
 menu.show_home();menu.action_buttons[1].pressed.emit();assert(menu.screen=="play")
 menu.show_home();menu.action_buttons[2].pressed.emit();assert(menu.screen=="challenges")
 app._home_play(false);root.size=Vector2i(414,896);await create_timer(.5).timeout;await snap("battle")
 assert(app.battlefield.visible)
 app.queue_free();await process_frame
 print("PASS responsive title, controls, camera drift, lesson list, play, challenges and battlefield")
 quit()
