extends SceneTree
const Main=preload("res://scripts/main.gd")
const Motion=preload("res://scripts/knight_motion.gd")
var failures=0
func check(ok:bool,label:String):
 if ok:print("PASS ",label)
 else:failures+=1;push_error("FAIL "+label)
func _initialize():call_deferred("run")
func run():
 var app=Main.new();app.intro_enabled=false;root.add_child(app);await process_frame
 var node=app.pieces[1];var origin=node.position;var fen=app.game.fen()
 for dx in [-2,-1,1,2]:
  for dz_sign in [-1,1]:
   node.position=origin
   var d=Vector3(dx,0,dz_sign*(1 if abs(dx)==2 else 2));var target=origin+d
   var state=Motion.travel_state(node,target,target,1.65,3.0)
   Motion.travel_frame(.16*1.65+.70*1.65*.64,node,state)
   check(Vector2(node.position.x-state.corner.x,node.position.z-state.corner.z).length()<.001,"Knight reaches the L corner in direction "+str(d))
   check(node.position.y>origin.y+2.0,"Knight clears tall pieces while crossing")
   Motion.travel_frame(1.65,node,state)
   check(node.position.distance_to(target)<.001 and state.footfalls==1,"Knight lands exactly once on target")
 check(app.game.fen()==fen,"Jump sampling never changes chess state")
 app._new_game();app._make_move(1,18)
 await create_timer(.55).timeout
 check(app.pieces[1].position.y>origin.y+.3,"Opening knight jumps over occupied pawn rank")
 app._skip();await create_timer(.15).timeout
 check(not app.busy and app.game.history.size()==1 and app.pieces.has(18),"Skipping jump commits exactly one legal move")
 app._undo();check(app.pieces.has(1) and app.game.history.size()==0,"Undo restores knight after jump")
 for cue in ["horse_call","camel_call","elephant_call"]:
  check(app.sound.streams.has(cue) and app.sound.streams[cue]!=null,"Animal vocal recording loads: "+cue)
 app.sound.muted=false;app.sound.volume=.2;app.sound.play("horse_call");app.sound.stop_all()
 check(not app.sound.call_voice.playing,"Cancel stops animal voice")
 for fast in [false,true]:
  app._new_game(true);app.cinematic=not fast
  app.game=Main.Rules.new("7k/7p/8/8/4p3/8/3N4/K7 w - - 0 1")
  app._sync_pieces();app._update_ui();app._make_move(11,28)
  for i in range(140):
   if not app.busy:break
   await create_timer(.05).timeout
  check(not app.busy and app.pieces.has(28) and app.game.history.size()==1,"Knight capture completes in "+("fast" if fast else "cinematic")+" mode")
 app._new_game();app.queue_free();node=null
 await process_frame;await process_frame
 print("KNIGHT_JUMP_TESTS_COMPLETE failures=",failures);quit(failures)
