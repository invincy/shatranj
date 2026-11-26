extends SceneTree
func _initialize():call_deferred("run")
func run():
 var app=load("res://scripts/main.gd").new();app.intro_enabled=false;root.add_child(app);await process_frame
 app.computer.set_process(false)
 app._show_home();app._start_computer(4,"w")
 assert(app.computer.enabled and app.computer.level==4 and not app.computer.opponents_turn())
 app._make_move(12,28);app._skip()
 assert(app.computer.opponents_turn())
 app._select(52);assert(app.selected==-1)
 var fen=app.game.fen();app.computer.thinking=true;app.computer.requested_fen=fen
 app.computer.accept({"fen":"stale","move":"e7e5"});assert(app.game.fen()==fen)
 app.computer.accept({"fen":fen,"move":"e7e5"});assert(app.busy);app._skip()
 assert(app.game.history.size()==2 and app.game.turn=="w")
 app._undo();assert(app.game.history.is_empty() and app.game.turn=="w")
 app._make_move(12,28);app._skip();app._undo();assert(app.game.history.is_empty())
 app._start_computer(5,"b");assert(app.computer.opponents_turn())
 app.computer.thinking=true;app.computer.requested_fen=app.game.fen()
 app.computer.accept({"fen":app.game.fen(),"move":"e2e4"});app._skip()
 assert(app.game.turn=="b")
 app._make_move(52,36);app._skip();app._undo();assert(app.game.history.size()==1 and app.game.turn=="b")
 app.computer.thinking=true;app.computer.requested_fen=app.game.fen();app._show_home()
 assert(not app.computer.thinking)
 var match_game=app.game
 app._begin_training("basics",0);assert(not app.computer.opponents_turn())
 app._show_home();assert(app.game==match_game and app.computer.enabled)
 app._start_local();assert(not app.computer.enabled and app.game.history.is_empty())
 app.queue_free();await process_frame
 print("PASS computer ownership, stale moves, reply animation, undo pair/pending/black, home cancellation, tutorial restore, local match")
 quit()
