extends SceneTree
const Main=preload("res://scripts/main.gd")
var failures:=0
func check(ok: bool,label: String):
 if ok:print("PASS ",label)
 else:failures+=1;push_error(label)
func _initialize():call_deferred("run")
func run():
 var app=Main.new();app.intro_enabled=false;root.add_child(app);await process_frame
 check(not app.developer_mode and app.sidebar_tabs.is_tab_hidden(2),"Player mode hides reset studies by default")
 check(is_equal_approx(app.piece_badges.opacity,.55) and is_equal_approx(app.badge_opacity_slider.value,.55),"Opacity control matches translucent badge setting")
 app.badge_opacity_slider.value=.3
 check(is_equal_approx(app.piece_badges.opacity,.3),"Opacity slider changes badge rendering")
 app._knight_study();var board=app.game.board.duplicate()
 app._set_developer_mode(true);app.sidebar_tabs.current_tab=2
 check(not app.sidebar_tabs.is_tab_hidden(2),"Developer studies are accessible")
 app._set_developer_mode(false)
 check(app.sidebar_tabs.current_tab==0 and app.sidebar_tabs.is_tab_hidden(2),"Leaving Developer mode returns safely to Match")
 check(app.game.board==board and app.game.history.size()==1,"Mode changes preserve the active match")
 app._skip();app._undo();await process_frame
 check(app.game.history.is_empty() and app.pieces.has(1),"Skip and Undo still work after mode changes")
 app.sidebar_tabs.current_tab=1;app.tilt_slider.value=35
 check(is_equal_approx(app.view_tilt,35),"Sidebar tilt still controls camera")
 app.queue_free();await process_frame;await process_frame
 print("UI_TESTS_COMPLETE failures=",failures);quit(failures)
