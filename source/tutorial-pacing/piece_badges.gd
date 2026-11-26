extends Control
var game_view: Node
var enabled := true
var opacity := .55
var tutorial := false
var icons: Dictionary = {}

func _ready() -> void:
	for role in SYMBOLS: icons[role]=load("res://assets/icons/"+role+".svg")
const SYMBOLS={"p":"P", "r":"R", "b":"B", "n":"N", "q":"Q", "k":"K"}

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not enabled or not is_instance_valid(game_view) or game_view.intro_active or (game_view.busy and not tutorial): return
	var cam: Camera3D=game_view.camera
	
	for node in game_view.pieces.values():
		if not is_instance_valid(node) or not node.visible: continue
		if tutorial and game_view.busy and node==game_view.pieces.get(game_view.last_move.get("from",-1)):continue
		var anchor: Vector3=node.global_position+Vector3(0,.18,0)
		if cam.is_position_behind(anchor): continue
		var at=cam.unproject_position(anchor)*size/Vector2(game_view.viewport.size)
		if not Rect2(Vector2.ZERO,size).has_point(at): continue
		var p: String=node.get_meta("piece"); var role=p.to_lower()
		var color=Color("c8e6d1") if p==p.to_lower() else Color("ffe2a6")
		# Size follows the projected tile width, rather than a fixed screen-size disc.
		var left=cam.unproject_position(anchor+Vector3(-.5,0,0))*size/Vector2(game_view.viewport.size)
		var right=cam.unproject_position(anchor+Vector3(.5,0,0))*size/Vector2(game_view.viewport.size)
		var front=cam.unproject_position(anchor+Vector3(0,0,.5))*size/Vector2(game_view.viewport.size)
		var back=cam.unproject_position(anchor+Vector3(0,0,-.5))*size/Vector2(game_view.viewport.size)
		var radius=clampf(maxf(left.distance_to(right),front.distance_to(back))*.22,4.0,12.0)
		draw_circle(at,radius,Color(0.025,.045,.05,.12*opacity))
		color.a=opacity*.55
		draw_arc(at,radius,0,TAU,32,color,1.0,true)
		color.a=opacity
		var icon: Texture2D=icons[role]
		draw_texture_rect(icon,Rect2(at-Vector2.ONE*radius*.7,Vector2.ONE*radius*1.4),false,color)
