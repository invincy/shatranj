extends SceneTree
var failures:=0
func check(ok:bool,title:String):
 if ok:print("PASS ",title)
 else:failures+=1;push_error(title)
func _initialize():call_deferred("run")
func run():
 var app=load("res://scripts/main.gd").new();app.intro_enabled=false;root.add_child(app);await process_frame
 app.game.play(12,28);app._sync_pieces();app.notation.append("Pyada e2-e4")
 var original=app.game;var fen:String=original.fen();var history=original.history.duplicate(true)
 app._show_home();check(app.board_container.anchor_right==1.0,"menu uses full-screen battlefield")
 app._begin_training("basics");var t=app.training
 check(app.game!=original and app.pieces.has(12),"tutorial uses real 3D pawn and separate match state")
 check(t.phase=="demo" and not t.next_button.visible,"lesson starts with demonstration and hides Next")
 t.tap(12);check(not t.selected,"practice input is blocked during demonstration")
 await practice(t)
 t.tap(28);check(app.game.history.is_empty(),"must select lesson piece first")
 var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
 click.position=app.camera.unproject_position(app._square_pos(12))*app.board_container.size/Vector2(app.viewport.size)
 app._board_input(click);check(t.selected,"real board click selects tutorial piece")
 t.tap(13);check(app.game.history.is_empty(),"illegal moves rejected")
 t.tap(28);check(app.busy,"pawn movement animates")
 while app.busy:await process_frame
 check(t.complete and app.pieces.has(28),"animation completes exercise")
 for index in range(1,7):
  t.load_lesson(index);await practice(t);var square:int=t.Lessons.LESSONS[index].from;t.tap(square)
  var target:int=6 if index==6 else app.game.legal_moves(square)[0].to
  t.tap(target)
  while app.busy:await process_frame
  check(t.complete and t.next_button.visible,"3D basic lesson "+str(index))
 check(app.game.board[5]=="R" and app.pieces.has(5),"castling moves real rook too")
 app._show_home();check(app.game==original and app.game.fen()==fen and app.game.history==history and app.notation==["Pyada e2-e4"],"leaving restores exact match and history")
 app._begin_training("tactics");t=app.training;await practice(t);t.tap(12);t.tap(11);check(app.game.history.is_empty(),"pin blocks sideways move")
 t.tap(60)
 while app.busy:await process_frame
 check(t.complete and app.pieces.has(60),"pin capture completes on 3D board")
 t.load_lesson(8);await practice(t);t.tap(18);t.tap(35)
 while app.busy:await process_frame
 check(t.complete and app.game.in_check("b") and app.game._attacks_from(35,45),"knight jump produces real fork")
 app._show_home();app._begin_training("basics");await practice(app.training);app.training.tap(12);app.training.tap(28);app._show_home()
 check(app.game==original and app.game.fen()==fen and not app.busy,"exit during animation safely restores match")
 app._home_play();check(app.game_ui.visible and not app.home_active,"resume returns to play")
 app.queue_free();await create_timer(.5).timeout
 print("TRAINING_TESTS_COMPLETE failures=",failures);quit(failures)

func practice(t):
 var deadline=Time.get_ticks_msec()+33000
 while t.phase!="practice" and Time.get_ticks_msec()<deadline:await process_frame
 check(t.phase=="practice" and not t.app.busy,"demonstration finishes and unlocks practice "+str(t.index))
 check(t.app.game.history.is_empty() and t.app.game.fen()==t.Lessons.LESSONS[t.index].fen,"demonstration restores original lesson position "+str(t.index))
 check(not t.complete and not t.next_button.visible,"demonstration cannot complete the user's challenge")
