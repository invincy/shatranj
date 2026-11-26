extends Node
## The engine suggests UCI moves. ChessRules remains the authority.
var app
var enabled:=false
var human_side:="w"
var level:=4
var thinking:=false
var requested_fen:=""
var failed:=false
var bridge
var poll_elapsed:=0.0
var retry:Button

func _ready():
	if OS.has_feature("web"):bridge=JavaScriptBridge.get_interface("shatranjComputer")

func cancel():
	if bridge:bridge.cancel()
	thinking=false;requested_fen="";failed=false
	if is_instance_valid(retry):retry.queue_free()

func opponents_turn() -> bool:
	return enabled and not is_instance_valid(app.training) and app.game.turn!=human_side

func _process(delta):
	if not enabled or app.home_active or app.intro_active or app.busy or app.ended or is_instance_valid(app.training):return
	if not opponents_turn() or failed:return
	if not thinking:
		request_move();return
	poll_elapsed+=delta
	if poll_elapsed<.1:return
	poll_elapsed=0
	if bridge:
		var value=JSON.parse_string(str(bridge.poll()))
		if value is Dictionary:accept(value)

func request_move():
	if not bridge:
		failure("Computer play is available in the browser version.");return
	var legal:Array[String]=[]
	for move in app.game.legal_moves():
		legal.append(app.Rules.square_name(move.from)+app.Rules.square_name(move.to)+str(move.get("promotion","")))
	if legal.is_empty():return
	requested_fen=app.game.fen();thinking=true
	app.status_label.text="Stockfish · Level "+str(level)+" is thinking…"
	app.hint_label.text="You command "+("Saffron (White)" if human_side=="w" else "Emerald (Black)")
	bridge.search(requested_fen,level,JSON.stringify(legal))

func accept(value:Dictionary):
	if not thinking or not enabled or app.home_active or is_instance_valid(app.training) or app.busy or app.intro_active or app.ended:return
	if value.get("fen","")!=requested_fen or app.game.fen()!=requested_fen or not opponents_turn():return
	thinking=false
	if value.has("error"):failure(str(value.error));return
	var uci:String=value.get("move","")
	for move in app.game.legal_moves():
		var expected=app.Rules.square_name(move.from)+app.Rules.square_name(move.to)+str(move.get("promotion",""))
		if uci==expected:
			app._make_move(move.from,move.to,str(move.get("promotion","q")));return
	failure("The computer move was rejected. Please retry.")

func failure(message:String):
	failed=true;thinking=false
	app.status_label.text="Computer paused";app.sub_label.text=message
	if is_instance_valid(retry):retry.queue_free()
	retry=app._button("Retry computer",func():cancel())
	retry.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	retry.position.y=70
	app.game_ui.add_child(retry)

func _exit_tree():
	if bridge:bridge.cancel()
