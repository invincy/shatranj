extends Node3D

const Rules = preload("res://scripts/chess_rules.gd")
const OUTLINE = preload("res://scripts/outline.gdshader")
const STONE = preload("res://scripts/stone.gdshader")
const LIVING_SURFACE = preload("res://scripts/living_surface.gdshader")
const COURT = preload("res://scripts/stone_court.gd")
const HaathiMotion = preload("res://scripts/haathi_motion.gd")
const PyadaMotion = preload("res://scripts/pyada_motion.gd")
const RoyalMotion = preload("res://scripts/royal_motion.gd")
const KnightMotion = preload("res://scripts/knight_motion.gd")
const DustEffects = preload("res://scripts/dust_effects.gd")
const InfantryCapture = preload("res://scripts/infantry_capture.gd")
const BattleAudio = preload("res://scripts/battle_audio.gd")
const MountedMotion = preload("res://scripts/mounted_motion.gd")
const ROLES = {"r":"haathi","b":"oont","n":"ghoda","p":"pyada","q":"rani","k":"raja"}
const NAMES = {"r":"Rook (हाथी)","b":"Bishop (ऊँट)","n":"Knight (घोड़ा)","p":"Pawn (प्यादा)","q":"Queen (रानी)","k":"King (राजा)"}
const GOLD = Color("d8ad64")
const INK = Color("0b171b")
const LIGHT = Color("ece4cf")
const MUTED = Color("94aaa9")
const JADE = Color("66c8b2")

var dust_enabled := true
var ambient_dust: Node3D
var sound: Node
var game = Rules.new()
var computer
var world: Node3D
var court: Node3D
var battlefield: Node3D
var tiles: Array[MeshInstance3D] = []
var board_frame: Array[MeshInstance3D] = []
var scene_environment: Environment
var piece_badges: Control
var theme_index := 1
var training
var academy=preload("res://scripts/academy_progress.gd").new()
var mobile_layout
var ui_top:Control
var ui_side:Control
var ui_bottom:Control
var home_active := false
var home_menu: CanvasLayer
var game_ui: Control
var startup_intro := false
var developer_mode := false
var sidebar_tabs: TabContainer
var mode_selector: OptionButton
var badge_opacity_slider: HSlider
var theme_selector: OptionButton
var camera: Camera3D
var viewport: SubViewport
var board_container: SubViewportContainer
var pieces: Dictionary = {}
var facing_by_square: Dictionary = {}
var assets: Dictionary = {}
var material_cache: Dictionary = {}
var stone_roles: Array[String] = []
var surface_maps: Dictionary = {}
var markers: Array = []
var selected := -1
var busy := false
var cinematic := true
var flipped := false
var ended := false
var animation_serial := 0
var active_tween: Tween
var board_camera := Vector3(0,12.0,12.85)
var board_look := Vector3(0,.65,0)
var view_yaw := 0.0
var view_tilt := 22.0
var view_distance := 14.5
var rotate_slider: HSlider
var tilt_slider: HSlider
var zoom_slider: HSlider
var orbit_dragging := false
var pan_dragging := false
var status_label: Label
var sub_label: Label
var selection_label: Label
var hint_label: Label
var move_list: RichTextLabel
var turn_label: Label
var capture_label: Label
var check_label: Label
var skip_button: Button
var promotion_panel: PanelContainer
var move_count := 0
var notation: Array[String] = []
var last_move: Dictionary = {}
var qa := false
var intro_enabled := true
var intro_active := false
var intro_serial := 0
var intro_tween: Tween
var intro_panel: PanelContainer
var intro_title: Label
var intro_subtitle: Label
var intro_progress: ProgressBar

func _ready() -> void:
	academy.load_progress()
	ThemeDB.get_default_theme().default_font.fallbacks=[preload("res://assets/fonts/NotoSansDevanagari.ttf")]
	_configure_display()
	Engine.max_fps=30
	qa=OS.get_cmdline_user_args().has("--qa")
	sound=BattleAudio.new(); add_child(sound)
	_load_assets()
	_build_world()
	_build_ui()
	computer=preload("res://scripts/computer_player.gd").new();computer.app=self;add_child(computer)
	_sync_pieces()
	_update_ui()
	_change_theme(1)
	if OS.get_cmdline_user_args().has("--qa-intro"): _qa_intro_sequence()
	elif qa: _qa_sequence()
	elif OS.get_cmdline_user_args().has("--qa-walk"): _qa_walk_sequence()
	elif OS.get_cmdline_user_args().has("--qa-pyada"): _qa_pyada_sequence()
	elif OS.get_cmdline_user_args().has("--qa-portrait"): _qa_portrait_sequence()
	elif OS.get_cmdline_user_args().has("--qa-mounts"): _qa_mount_sequence()
	elif OS.get_cmdline_user_args().has("--qa-encounters"): _qa_encounters_sequence()
	elif OS.get_cmdline_user_args().has("--qa-refined-mounts"): _qa_refined_mounts_sequence()
	elif OS.get_cmdline_user_args().has("--qa-royal-arms"): _qa_royal_arms_sequence()
	elif OS.get_cmdline_user_args().has("--qa-armour"): _qa_armour_sequence()
	elif OS.get_cmdline_user_args().has("--qa-haathi-head"): _qa_haathi_head_sequence()
	elif OS.get_cmdline_user_args().has("--qa-haathi-body"): _qa_haathi_body_sequence()
	elif intro_enabled:call_deferred("_show_home")

func _show_home() -> void:
	if computer:computer.cancel()
	if intro_active:startup_intro=false;_end_intro()
	if is_instance_valid(training): training.leave()
	if busy:_skip()
	home_active=true;game_ui.hide();_clear_markers();selected=-1
	board_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view_preset("angled")
	_responsive()
	if not is_instance_valid(home_menu):
		home_menu=preload("res://scripts/home_menu.gd").new();home_menu.app=self;add_child(home_menu)
	else:home_menu.show();home_menu.show_home()

func _home_play(play_intro := true) -> void:
	home_active=false;home_menu.hide();game_ui.show()
	board_container.anchor_right=.76;board_container.anchor_top=.09;board_container.anchor_bottom=.96
	_view_preset("front")
	mobile_layout.drawer=false;_responsive()
	if play_intro and intro_enabled and game.history.is_empty():_start_intro()

func _show_academy() -> void:
	_show_home()
	home_menu.show_learn()

func _begin_training(category:String,lesson_index := -1) -> void:
	if computer:computer.cancel()
	if busy:_skip()
	if not is_instance_valid(home_menu):_show_home()
	home_active=false;home_menu.hide();game_ui.hide()
	board_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);board_container.anchor_right=.72
	training=preload("res://scripts/board_training.gd").new();training.app=self;training.category=category;training.start_index=lesson_index;add_child(training)

func _home_settings() -> void:
	_home_play(false);sidebar_tabs.current_tab=1
	mobile_layout.drawer=true;_responsive()

func _start_intro() -> void:
	if busy or intro_active or pieces.size()!=32 or not game.history.is_empty(): return
	intro_serial+=1; var serial=intro_serial
	intro_active=true; selected=-1; _clear_markers()
	intro_panel.visible=true; intro_progress.value=0
	if is_instance_valid(mobile_layout):mobile_layout.layout()
	status_label.text="Meet the armies"
	sub_label.text="An opening procession before the first move."
	selection_label.text="The royal battlefield"
	hint_label.text="Watch the tour, or skip to begin playing."
	turn_label.text="OPENING PROCESSION"
	camera.position=Vector3(-4.4,2.9,.05)
	camera.look_at(Vector3(-2.6,1.0,3.15))
	_update_court_visibility()
	for square in [0,1,2]:
		if pieces.has(square): _animate(pieces[square],"threat",.8)
	if not await _intro_shot(serial,Vector3(-2.1,2.7,-.35),Vector3(-2.25,1.0,3.15),1.7,"The vanguard","Haathi · Ghoda · Oont — strength, speed and reach.",22): return
	for square in [3,4]:
		if pieces.has(square): _animate(pieces[square],"victory",.85)
	if not await _intro_shot(serial,Vector3(.15,2.8,-.65),Vector3(0,1.1,3.3),1.6,"The royal command","Rani, the royal archer. Raja, the heart of the army.",45): return
	for square in [5,6,7,13,14,15]:
		if pieces.has(square): _animate(pieces[square],"threat",.85)
	if not await _intro_shot(serial,Vector3(3.8,2.8,.0),Vector3(2.5,.95,3.1),1.5,"The line holds","Armoured riders and spear soldiers stand ready.",65): return
	for square in [59,60]:
		if pieces.has(square): _animate(pieces[square],"victory",.9)
	if not await _intro_shot(serial,Vector3(5.8,5.5,-.5),Vector3(0,.8,-2.9),1.4,"A worthy rival","Across the board, the Emerald army awaits.",82): return
	if not await _intro_shot(serial,board_camera,board_look,1.2,"The battlefield is yours","The pieces are ready. Your first move writes the story.",100): return
	_end_intro()

func _intro_shot(serial: int,position: Vector3,target: Vector3,duration: float,title: String,subtitle: String,progress: float) -> bool:
	if serial!=intro_serial or not intro_active: return false
	intro_title.text=title; intro_subtitle.text=subtitle
	intro_tween=create_tween().set_parallel(true)
	intro_tween.tween_method(_camera_blend.bind(camera.position,position,camera.quaternion,_look_quat(position,target)),0.0,1.0,duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	intro_tween.tween_property(intro_progress,"value",progress,duration)
	# A cancellable presentation never owns chess state. A timer lets a killed
	# camera tween unwind without leaving its coroutine waiting on finished.
	await get_tree().create_timer(duration).timeout
	return serial==intro_serial and intro_active

func _end_intro() -> void:
	if not intro_active: return
	intro_serial+=1; intro_active=false
	if intro_tween and intro_tween.is_running(): intro_tween.kill()
	intro_panel.visible=false
	if is_instance_valid(mobile_layout):mobile_layout.layout()
	camera.position=board_camera; camera.look_at(board_look)
	_update_court_visibility()
	_sync_pieces(); _update_ui()
	sub_label.text="Your move · choose a piece to begin." if game.history.is_empty() else "The battlefield is yours again."
	if startup_intro:
		startup_intro=false;_show_home()

func _toggle_intro(on: bool) -> void:
	intro_enabled=on
	if not on: _end_intro()

func _load_assets() -> void:
	for surface in ["hide","cloth","leather","metal","wood","skin","fur","warsteel","elephanthide"]:
		surface_maps[surface]=[load("res://assets/surfaces/"+surface+"_detail.png"),load("res://assets/surfaces/"+surface+"_normal.png")]
	for role in ROLES.values():
		var path="res://assets/"+role+".glb"
		var sculpture="res://assets/"+role+"_stone.glb"
		if ResourceLoader.exists(sculpture): path=sculpture; stone_roles.append(role)
		if ResourceLoader.exists(path): assets[role]=load(path)
	if ResourceLoader.exists("res://assets/raja_mughal.glb"): assets["raja_mughal"]=load("res://assets/raja_mughal.glb")

func _living_material(kind: String,black: bool) -> Material:
	var key="living:"+str(black)+":"+kind
	if material_cache.has(key): return material_cache[key]
	var material:=ShaderMaterial.new(); material.shader=LIVING_SURFACE
	# Anatomy keeps natural colours on both teams. Cloth and trim carry allegiance.
	var palette={
		"hide":["91908a","91908a","elephanthide",.88,0.0,.65,2.2],
		"horn":["9c9584","9c9584","elephanthide",.76,0.0,.25,2.0],
		"ear":["918c83","918c83","hide",.85,0.0,.35,5.0],
		"horse":["78634e","6b5949","fur",.81,0.0,.40,4.0],
		"camel":["b1a084","a18f74","fur",.92,0.0,.65,3.0],
		"fur":["7d6a50","75634c","fur",.96,0.0,.45,3.0],
		"warsteel":["b5b0a3","abb4aa","warsteel",.72,.48,.35,5.0],
		"mounted_warsteel":["b4bfbd","acb9b6","warsteel",.64,.52,.22,5.0],
		"mounted_linen":["b9b19e","93a28e","cloth",.95,0.0,.16,15.0],
		"wardye":["a68a6a","728d7c","warsteel",.82,.12,.28,5.0],
		"warbrass":["bbae8d","b5bdac","warsteel",.65,.62,.15,6.0],
		"padding":["665642","394654","cloth",.98,0.0,.4,8.0],
		"skin":["b98d70","b98d70","skin",.57,0.0,.12,5.0],
		"cloth":["ab8c68","607e69","cloth",.94,0.0,.35,9.0],
		"linen":["d8cbb0","a2b9a1","cloth",.95,0.0,.30,10.0],
		"leather":["49301f","343d32","leather",.78,0.0,.40,8.0],
		"steel":["8e989e","929c91","metal",.43,.80,.12,6.0],
		"gold":["bd9345","c7c4aa","metal",.40,.80,.10,5.0],
		"ivory":["ded9ca","ded9ca","skin",.40,0.0,.05,4.0],
		"wood":["624027","483423","wood",.65,0.0,.25,5.0],
		"hair":["241c17","241c17","leather",.87,0.0,.18,8.0],
		"eye":["17130e","17130e","skin",.15,0.0,0.0,3.0],
		"gem":["227f75","a94244","skin",.18,.2,0.0,3.0],
		"queen_skin":["dfc3ad","dfc3ad","skin",.62,0.0,.055,6.0],
		"infantry_skin":["b39580","b39580","skin",.62,0.0,.10,6.0],
		"sclera":["aaa697","aaa697","skin",.36,0.0,0.0,3.0],
		"iris":["473522","473522","skin",.30,0.0,0.0,3.0],
		"infantry_steel":["a0a29f","929a91","metal",.53,.72,.20,7.0],
		"infantry_gold":["a79367","b9b9a1","metal",.49,.72,.15,6.0],
		"infantry_cloth":["a58a6b","607b69","cloth",.96,0.0,.45,12.0],
		"infantry_linen":["c6bfae","a2b39a","cloth",.96,0.0,.36,12.0],
		"royalcloth":["813e29","245449","cloth",.72,0.0,.10,20.0],
		"queencloth":["92513d","2f6257","cloth",.72,0.0,.10,20.0],
		"royalgold":["f3d071","f3d071","metal",.34,.72,.06,8.0],
		"royalsclera":["dedacb","dedacb","skin",.32,0.0,0.0,3.0],
		"royaliris":["302014","302014","skin",.25,0.0,0.0,3.0],
		"royallinen":["c6b596","a5b4a2","cloth",.92,0.0,.12,20.0],
	}
	var values: Array=palette.get(kind,palette.skin)
	material.set_shader_parameter("tint",Color(values[1] if black else values[0]).srgb_to_linear())
	material.set_shader_parameter("detail_map",surface_maps[values[2]][0])
	material.set_shader_parameter("normal_map",surface_maps[values[2]][1])
	material.set_shader_parameter("roughness_amount",values[3])
	material.set_shader_parameter("metal_amount",values[4])
	material.set_shader_parameter("normal_strength",values[5])
	material.set_shader_parameter("detail_scale",values[6])
	material.set_shader_parameter("royal_weave",1.0 if kind in ["royalcloth","queencloth"] else 0.0)
	material.set_shader_parameter("skin_paint_amount",1.0 if kind=="infantry_skin" else 0.0)
	material.set_shader_parameter("animal_paint_amount",1.0 if kind in ["hide","horse","camel"] else 0.0)
	material.set_shader_parameter("armour_paint_amount",1.0 if kind in ["warsteel","wardye","mounted_warsteel"] else 0.0)
	if kind=="ear":
		material.set_shader_parameter("accent",Color("a68e83").srgb_to_linear())
		material.set_shader_parameter("mottle_amount",.25)
	material_cache[key]=material; return material

func _mat(color: Color, metal := 0.0) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new()
	m.albedo_color=color; m.metallic=metal; m.roughness=.65
	return m

func _stone(color: Color) -> ShaderMaterial:
	var mat:=ShaderMaterial.new(); mat.shader=STONE; mat.set_shader_parameter("stone_color",color)
	return mat

func _box(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var ob:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=size
	ob.mesh=mesh; ob.material_override=material; ob.position=pos; parent.add_child(ob)
	return ob

func _build_world() -> void:
	var layer:=CanvasLayer.new(); add_child(layer)
	board_container=SubViewportContainer.new()
	board_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_container.anchor_right=.76; board_container.anchor_top=.09
	board_container.anchor_bottom=.96; board_container.stretch=true
	board_container.mouse_filter=Control.MOUSE_FILTER_PASS
	layer.add_child(board_container)
	viewport=SubViewport.new(); viewport.size=Vector2i(1094,783); viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS; viewport.msaa_3d=Viewport.MSAA_2X
	board_container.add_child(viewport)
	world=Node3D.new(); viewport.add_child(world)
	var envnode:=WorldEnvironment.new(); var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR; env.background_color=Color("080d17")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("b9c5d1"); env.ambient_light_energy=.46
	env.fog_enabled=true; env.fog_light_color=Color("29252a"); env.fog_density=.009
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	# A small sky radiance map supplies metal reflections in Compatibility.
	# The visible background remains the palace; no screen-space effects needed.
	var sky:=Sky.new(); var sky_mat:=ProceduralSkyMaterial.new()
	sky_mat.sky_top_color=Color("63798c"); sky_mat.sky_horizon_color=Color("d5c5aa")
	sky_mat.ground_bottom_color=Color("242127"); sky_mat.ground_horizon_color=Color("8b7864")
	sky.sky_material=sky_mat; sky.radiance_size=Sky.RADIANCE_SIZE_128
	env.sky=sky; env.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	scene_environment=env
	envnode.environment=env; world.add_child(envnode)
	var sun:=DirectionalLight3D.new(); sun.name="BattleSun"; sun.rotation_degrees=Vector3(-52,-28,0)
	sun.light_color=Color("fff1dc"); sun.light_energy=.75; sun.shadow_enabled=true
	sun.shadow_opacity=.55
	sun.directional_shadow_max_distance=32; world.add_child(sun)
	_box(world,Vector3(200,.10,200),Vector3(0,-.86,0),_mat(Color("101116")))
	court=COURT.build(world)
	battlefield=preload("res://scripts/battlefield.gd").build(world); battlefield.visible=false
	board_frame.append(_box(world,Vector3(9.38,.35,9.38),Vector3(0,-.34,0),_mat(Color("100f18"),.15)))
	board_frame.append(_box(world,Vector3(9.36,.055,9.36),Vector3(0,-.15,0),_mat(Color("bb8a43"),.45)))
	board_frame.append(_box(world,Vector3(9.18,.12,9.18),Vector3(0,-.07,0),_mat(Color("241b24"),.08)))
	board_frame.append(_box(world,Vector3(8.15,.035,8.15),Vector3(0,.015,0),_mat(Color("d8ad64"),.45)))
	for x in [-4.4,4.4]:
		for z in [-4.4,4.4]:
			var corner=_box(world,Vector3(.12,.025,.12),Vector3(x,.01,z),_mat(GOLD,.5))
			corner.rotation.y=PI/4
	var pale:=_stone(Color("536376")); var dark:=_stone(Color("27313f"))
	for square in range(64):
		var tile:=MeshInstance3D.new()
		tile.mesh=preload("res://scripts/worn_tile.gd").create(square)
		tile.position=_square_pos(square)+Vector3(0,-.005,0)
		tile.material_override=pale if (square%8+square/8)%2==1 else dark
		world.add_child(tile); tiles.append(tile)
	for i in range(8):
		_board_letter("abcdefgh"[i],Vector3(i-3.5,.05,4.29))
		_board_letter(str(i+1),Vector3(-4.29,.05,3.5-i))
	camera=Camera3D.new(); world.add_child(camera); camera.position=board_camera
	camera.fov=50; camera.near=.1; camera.far=150; camera.look_at(board_look); camera.current=true
	board_container.gui_input.connect(_board_input)
	ambient_dust=DustEffects.emitter();world.add_child(ambient_dust);ambient_dust.position.y=.28
	_update_ambient_dust()

func _board_letter(value: String, pos: Vector3) -> void:
	var label:=Label3D.new(); label.text=value; label.position=pos
	label.rotation_degrees.x=-90; label.font_size=48; label.pixel_size=.004
	label.modulate=GOLD; label.outline_size=0; world.add_child(label)

func _square_pos(square: int) -> Vector3:
	return Vector3(square%8-3.5,.055,3.5-square/8)

func _animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node
	for child in node.get_children():
		var player=_animation_player(child)
		if player: return player
	return null

func _royal_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D: return node
	for child in node.get_children():
		var found=_royal_skeleton(child)
		if found: return found
	return null

func _held_arrow(node: Node,shown: bool) -> void:
	if node is MeshInstance3D and str(node.name).begins_with("RoyalHeldArrow"): node.visible=shown
	for child in node.get_children(): _held_arrow(child,shown)

func _bow_release_point(node: Node3D) -> Vector3:
	var skeleton=_royal_skeleton(node)
	if skeleton:
		var bone=skeleton.find_bone("bow_draw")
		if bone>=0: return skeleton.to_global(skeleton.get_bone_global_pose(bone).origin)
	return node.position+Vector3(0,.8,0)

func _tutorial_demo() -> bool:
	return is_instance_valid(training) and training.phase=="demo"

func _presentation_speed() -> float:
	if _tutorial_demo():return .9
	return .45 if is_instance_valid(training) else .75

func _presentation_tween() -> Tween:
	return create_tween().set_speed_scale(_presentation_speed())

func _animate(node: Node3D, clip: String, speed := 1.0) -> void:
	if node.get_parent()==world and clip!="idle":speed*=_presentation_speed()
	var player=_animation_player(node)
	if not player: return
	for name in player.get_animation_list():
		if str(name).to_lower().ends_with(clip):
			if clip in ["idle","walk"]: player.get_animation(name).loop_mode=Animation.LOOP_LINEAR
			player.play(name,.12,speed); return

func _travel(tween: Tween, node: Node3D, target: Vector3, duration: float) -> void:
	var distance=node.position.distance_to(target)
	if distance<.001: return
	var heading=target-node.position
	var elephant=str(node.get_meta("piece","")).to_lower()=="r" and stone_roles.has("haathi")
	# The baked Haathi stance covers 0.42/0.70 Blender units per cycle.
	# Linear root motion and matching clip speed prevent stance feet skating.
	if str(node.get_meta("piece", "")).to_lower()=="n" and node.has_meta("jump_target"):
		var board_target: Vector3=node.get_meta("jump_target"); node.remove_meta("jump_target")
		var clearance=1.05
		# Clear only pieces along the two legs of the L-shaped route.
		var d=board_target-node.position
		var corner=node.position+(Vector3(d.x,0,0) if absf(d.x)>absf(d.z) else Vector3(0,0,d.z))
		for other in pieces.values():
			if other==node or other.position.distance_to(board_target)<.1: continue
			var near_first=Geometry3D.get_closest_point_to_segment(other.position,node.position,corner)
			var near_second=Geometry3D.get_closest_point_to_segment(other.position,corner,board_target)
			if minf(other.position.distance_to(near_first),other.position.distance_to(near_second))<.65:
				clearance=maxf(clearance,float({"p":1.85,"q":2.5,"k":2.6,"r":3.0,"n":2.4,"b":2.6}.get(str(other.get_meta("piece","")).to_lower(),2.0)))
		var state=KnightMotion.travel_state(node,target,board_target,2.4 if _tutorial_demo() else (1.65 if cinematic else 1.0),clearance)
		node.set_meta("travel_state",state)
		tween.tween_method(_travel_frame.bind(node,state,KnightMotion.travel_frame),0.0,state.duration,state.duration)
	elif elephant and cinematic:
		var state=HaathiMotion.travel_state(node,target,duration)
		node.set_meta("travel_state",state)
		tween.tween_method(_travel_frame.bind(node,state,HaathiMotion.travel_frame),0.0,state.duration,state.duration)
	elif elephant:
		node.rotation.y=atan2(heading.x,heading.z)
		_animate(node,"walk",1.5*distance/(duration*(.42/.70)*.87))
		tween.tween_property(node,"position",target,duration).set_trans(Tween.TRANS_LINEAR)
	elif str(node.get_meta("piece","")).to_lower()=="p" and cinematic:
		var state=PyadaMotion.travel_state(node,target,duration)
		tween.tween_method(_travel_frame.bind(node,state,PyadaMotion.travel_frame),0.0,state.duration,state.duration)
	elif str(node.get_meta("piece","")).to_lower() in ["n","b"] and cinematic:
		var state=MountedMotion.travel_state(node,target,duration)
		node.set_meta("travel_state",state)
		tween.tween_method(_travel_frame.bind(node,state,MountedMotion.travel_frame),0.0,state.duration,state.duration)
	elif str(node.get_meta("piece","")).to_lower() in ["q","k"] and cinematic:
		var state=RoyalMotion.travel_state(node,target,duration)
		node.set_meta("travel_state",state)
		tween.tween_method(_travel_frame.bind(node,state,RoyalMotion.travel_frame),0.0,state.duration,state.duration)
	elif str(node.get_meta("piece","")).to_lower() in ["n","b"]:
		node.rotation.y=atan2(heading.x,heading.z)
		_animate(node,"walk",distance/(duration*.42*.78))
		tween.tween_property(node,"position",target,duration).set_trans(Tween.TRANS_LINEAR)
	else:
		node.rotation.y=atan2(heading.x,heading.z)
		_animate(node,"walk",2.0)
		tween.tween_property(node,"position",target,duration).set_trans(Tween.TRANS_SINE)

func _travel_frame(elapsed: float,node: Node3D,state: Dictionary,frame: Callable) -> void:
	frame.call(elapsed,node,state)
	var role=str(node.get_meta("piece","")).to_lower()
	if role in ["q","k"] and elapsed>=state.duration-.0001: _animate(node,"idle")
	var stride=RoyalMotion.STRIDE if role in ["q","k"] else (HaathiMotion.STRIDE if role=="r" else (PyadaMotion.STRIDE if role=="p" else .42*.78))
	var distance: float=state.start.distance_to(node.position)
	var step=int(state.get("footfalls",0)) if role in ["q","k"] or state.has("corner") else int(distance/(stride/2.0))
	if step>int(state.get("sound_step",0)):
		state.sound_step=step
		sound.play("elephant" if role=="r" else ("hoof" if role in ["n","b"] else "foot"))

func _royal_aim_turn(p: float,node: Node3D,yaw: float,angle: float) -> void:
	RoyalMotion.turn_frame(p,node,yaw,angle)
	var count=int(node.get_meta("footfalls",0))
	if count>int(node.get_meta("turn_sound_step",0)):
		node.set_meta("turn_sound_step",count);sound.play("foot")

func _travel_time(node: Node3D, target: Vector3, quick: float) -> float:
	if cinematic and str(node.get_meta("piece","")).to_lower() in ["n","b"]:
		return clampf(node.position.distance_to(target)/1.6,.35,2.8)
	if cinematic and str(node.get_meta("piece","")).to_lower()=="p":
		return clampf(node.position.distance_to(target)/1.1,.3,2.0)
	if cinematic and str(node.get_meta("piece","")).to_lower()=="r":
		return clampf(node.position.distance_to(target)/.85,.45,5.5)
	if cinematic and str(node.get_meta("piece","")).to_lower() in ["q","k"]:
		return clampf(node.position.distance_to(target)/.72,.45,9.5)
	return maxf(quick,.8)

func _recolor(node: Node, black: bool, role: String) -> void:
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var mat=node.mesh.surface_get_material(surface)
			if mat is StandardMaterial3D:
				var name=mat.resource_name
				var kind="skin"
				if name.begins_with("Living"): kind=name.trim_prefix("Living").split(".")[0].to_lower()
				elif name.begins_with("Gold") or name.begins_with("AntiqueGold"): kind="gold"
				elif name.begins_with("Steel") or name.begins_with("Army"): kind="steel"
				elif name.begins_with("Gem"): kind="gem"
				elif name.begins_with("Cloth"): kind="cloth"
				elif name.begins_with("Dark"): kind="hair"
				elif name.begins_with("Leather") or name.begins_with("Base"): kind="leather"
				elif name.begins_with("Animal"): kind="hide" if role=="haathi" else "horse"
				elif name.begins_with("Mountskin"): kind="camel"
				elif name.begins_with("Ivory"): kind="ivory"
				if role in ["pyada","ghoda","oont"] and kind in ["skin","steel","gold","cloth","linen"]: kind="infantry_"+kind
				if role in ["ghoda","oont"]:
					if kind=="warsteel": kind="mounted_warsteel"
					elif kind=="infantry_linen": kind="mounted_linen"
				if role in ["rani","raja"]:
					if kind in ["skin","gold"]: kind="infantry_"+kind
					elif kind=="cloth": kind="royalcloth"
					elif kind=="linen": kind="royallinen"
					elif kind=="warsteel": kind="mounted_warsteel"
				if role=="rani" and kind=="infantry_skin": kind="queen_skin"
				if role=="rani" and kind=="royalcloth": kind="queencloth"
				if role in ["rani","raja"]:
					if kind in ["mounted_warsteel","infantry_gold"]:kind="royalgold"
					elif kind=="sclera":kind="royalsclera"
					elif kind=="iris":kind="royaliris"
				node.set_surface_override_material(surface,_living_material(kind,black))
	for child in node.get_children(): _recolor(child,black,role)

func _piece(p: String, square: int) -> Node3D:
	var root:=Node3D.new(); world.add_child(root); root.position=_square_pos(square)
	root.rotation.y=PI if Rules.side(p)=="w" else 0.0
	if facing_by_square.has(square): root.rotation.y=facing_by_square[square]
	var role: String=ROLES[p.to_lower()]
	if assets.has(role):
		var variant="raja_mughal" if role=="raja" and Rules.side(p)=="b" and assets.has("raja_mughal") else role
		var model=assets[variant].instantiate(); root.add_child(model); model.scale=Vector3.ONE*.78
		root.set_meta("model_variant",variant)
		model.position.y=.038 # Piece root is the marker plane; soles meet the raised tile surface.
		if role=="haathi" and stone_roles.has(role): model.scale=Vector3(.87,1.10,.87)
		elif role=="raja": model.scale=Vector3(.94,1.18,.94)
		elif role=="rani": model.scale=Vector3(.92,1.14,.92)
		_recolor(model,Rules.side(p)=="b",role)
	else:
		var fallback:=MeshInstance3D.new(); var mesh:=CylinderMesh.new()
		mesh.top_radius=.17; mesh.bottom_radius=.28; mesh.height=.8; fallback.mesh=mesh
		fallback.position.y=.4; fallback.material_override=_mat(JADE if Rules.side(p)=="b" else LIGHT)
		root.add_child(fallback)
	# Frozen idle poses keep all 32 rigs cheap; active characters animate on demand.
	root.set_meta("piece",p); return root

func _sync_pieces() -> void:
	for node in pieces.values():
		if is_instance_valid(node): node.queue_free()
	pieces.clear()
	for square in range(64):
		if game.board[square]!="": pieces[square]=_piece(game.board[square],square)
	_clear_markers()
	if not last_move.is_empty():
		_marker(last_move.from,Color("9c8e46"),false)
		_marker(last_move.to,Color("9c8e46"),false)
	if game.in_check():
		var king=game.board.find("K" if game.turn=="w" else "k")
		_marker(king,Color("df7959"),false)
		for attacker_square in game.checking_squares():
			_marker(attacker_square,GOLD,false)
			_animate(pieces[attacker_square],"threat",1.3)
			if str(game.board[attacker_square]).to_lower() in ["r","b","q"]:
				var start=_square_pos(attacker_square)+Vector3(0,.035,0)
				var end=_square_pos(king)+Vector3(0,.035,0)
				var line=_box(world,Vector3(.035,.018,start.distance_to(end)),(start+end)*.5,_mat(Color("e6ae6a")))
				line.rotation.y=atan2(end.x-start.x,end.z-start.z); markers.append(line)

func _marker(square: int, color: Color, dot: bool) -> void:
	var ob:=MeshInstance3D.new(); var m:=_mat(color)
	m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	if dot:
		var mesh:=CylinderMesh.new(); mesh.top_radius=.115; mesh.bottom_radius=.115; mesh.height=.025
		ob.mesh=mesh
	else:
		var mesh:=TorusMesh.new(); mesh.inner_radius=.36; mesh.outer_radius=.43; mesh.rings=24; mesh.ring_segments=8
		ob.mesh=mesh
	ob.material_override=m; ob.position=_square_pos(square)+Vector3(0,.05,0)
	world.add_child(ob); markers.append(ob)

func _clear_markers() -> void:
	for node in markers:
		if is_instance_valid(node): node.queue_free()
	markers.clear()

func _board_input(event: InputEvent) -> void:
	if home_active:return
	if event is InputEventMagnifyGesture:
		_set_view(view_yaw,view_tilt,view_distance/maxf(event.factor,.1)); return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_MIDDLE:
		pan_dragging=event.pressed; return
	if event is InputEventMouseMotion and (pan_dragging or (orbit_dragging and event.shift_pressed)):
		var right=camera.global_basis.x; var forward=Vector3(right.z,0,-right.x)
		board_look+=(-right*event.relative.x-forward*event.relative.y)*view_distance*.0015
		board_look.x=clampf(board_look.x,-4,4); board_look.z=clampf(board_look.z,-4,4)
		_set_view(view_yaw,view_tilt,view_distance); return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT:
		orbit_dragging=event.pressed; return
	if event is InputEventMouseMotion and orbit_dragging:
		_set_view(view_yaw-event.relative.x*.35,view_tilt+event.relative.y*.25,view_distance); return
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		_set_view(view_yaw,view_tilt,view_distance+(-.8 if event.button_index==MOUSE_BUTTON_WHEEL_UP else .8)); return
	if busy or ended or intro_active: return
	if computer and computer.opponents_turn():return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var point=event.position*Vector2(viewport.size)/board_container.size
		var origin=camera.project_ray_origin(point); var direction=camera.project_ray_normal(point)
		var hit=Plane(Vector3.UP,.055).intersects_ray(origin,direction)
		if hit==null: return
		var file=int(floor(hit.x+4)); var rank=int(floor(4-hit.z))
		if file<0 or file>7 or rank<0 or rank>7: _select(-1); return
		var square=rank*8+file
		if is_instance_valid(training):
			training.tap(square);return
		if selected>=0:
			for m in game.legal_moves(selected):
				if m.to==square:
					if m.has("promotion"): _ask_promotion(selected,square)
					else: _make_move(selected,square)
					return
		_select(square if Rules.side(game.board[square])==game.turn else -1)

func _select(square: int) -> void:
	if intro_active or (computer and computer.opponents_turn()): return
	selected=square; _clear_markers()
	if square<0:
		selection_label.text="Choose your piece"; hint_label.text="Tap a piece, then a highlighted square."; return
	_marker(square,GOLD,false)
	var moves=game.legal_moves(square)
	for m in moves: _marker(m.to,Color("e58d6c") if m.captured!="" else JADE,m.captured=="")
	selection_label.text=NAMES[str(game.board[square]).to_lower()]+"  ·  "+Rules.square_name(square).to_upper()
	hint_label.text=str(moves.size())+" legal moves · "+{"r":"Elephant · straight lines","b":"Camel rider · diagonals","n":"Mounted warrior · L-shaped jumps","p":"Spear soldier · forward advance","q":"Royal archer · straight & diagonal","k":"Royal commander · one square"}[str(game.board[square]).to_lower()]

func _make_move(a: int,b: int,promotion := "q") -> void:
	if busy or ended or intro_active: return
	var record=game.play(a,b,promotion)
	if record.is_empty(): return
	busy=true; selected=-1; animation_serial+=1; var serial=animation_serial
	skip_button.visible=cinematic
	last_move=record; _clear_markers()
	var capture=record.captured!=""; var mate=record.result=="checkmate"
	var name: String=NAMES[str(record.piece).to_lower()]
	var text=Rules.square_name(a)+"–"+Rules.square_name(b)
	if record.get("castle",false): text="O-O" if b>a else "O-O-O"
	else:
		text=name+"  "+Rules.square_name(a)+( " × " if capture else " · ")+Rules.square_name(b)
		if record.has("promotion"): text+=" = "+NAMES[record.promotion]
	text+="#" if mate else (" +" if record.check else "")
	notation.append(text); _update_ui()
	status_label.text=(name+" captures" if capture else ("Royal escort" if record.get("castle",false) else name+" advances"))
	var attacker: Node3D=pieces[a]; var destination=_square_pos(b)
	var animal_cue={"n":"horse_call","b":"camel_call","r":"elephant_call"}.get(str(record.piece).to_lower(),"")
	if animal_cue!="":
		if capture:
			if not (cinematic and str(record.piece).to_lower()=="r"):sound.animal(str(record.piece),"attack")
		else:sound.play(animal_cue)
	if str(record.piece).to_lower()=="n": attacker.set_meta("jump_target",destination)
	if str(record.piece).to_lower()!="q" or not capture: _animate(attacker,"walk",2.0)
	var direction=destination-attacker.position; direction.y=0
	if direction.length()>.01 and not cinematic: attacker.rotation.y=atan2(direction.x,direction.z)
	var victim: Node3D=pieces.get(record.get("capture_square",b)) if capture else null
	if capture and cinematic:
		skip_button.visible=true
		var archer=str(record.piece).to_lower()=="q"
		var mounted=str(record.piece).to_lower() in ["n","b"]
		var reach=1.12 if str(record.piece).to_lower()=="p" else (1.0 if str(record.piece).to_lower()=="r" else (.82 if str(record.piece).to_lower()=="k" else .90))
		var staging=attacker.position if archer else destination-direction.normalized()*reach
		if mounted: staging=MountedMotion.staging(attacker,victim,direction.normalized())
		if str(record.piece).to_lower()=="n":
			var short_leg=Vector3(0,0,direction.z) if absf(direction.x)>absf(direction.z) else Vector3(direction.x,0,0)
			staging=destination-short_leg.normalized()*.65
		active_tween=_presentation_tween().set_parallel(true)
		if not archer: _travel(active_tween,attacker,staging,_travel_time(attacker,staging,.50))
		else:
			var angle=wrapf(atan2(direction.x,direction.z)-attacker.rotation.y,-PI,PI)
			active_tween.tween_method(_royal_aim_turn.bind(attacker,attacker.rotation.y,angle),0.0,1.0,maxf(.16,RoyalMotion.turn_duration(angle)))
		var defender_heading=staging-victim.position
		var defender_yaw=victim.rotation.y+wrapf(atan2(defender_heading.x,defender_heading.z)-victim.rotation.y,-PI,PI)
		active_tween.tween_property(victim,"rotation:y",defender_yaw,.40).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var focus=(destination+staging)*.5+Vector3(0,.95,0)
		var distance=maxf(1.0,staging.distance_to(destination)/2.0) if archer else 1.0
		var profile=Vector3(-direction.z,0,direction.x).normalized()
		var close=focus+(profile*4.5+Vector3(0,2.2,0)-direction.normalized()*.5)*distance
		if mounted: close=MountedMotion.encounter_camera(focus,direction)
		if not _tutorial_demo():
			active_tween.tween_method(_camera_blend.bind(camera.position,close,camera.quaternion,_look_quat(close,focus)),0.0,1.0,.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await active_tween.finished
		if serial!=animation_serial: return
		if str(record.piece).to_lower()=="r" and stone_roles.has("haathi"):
			await _haathi_capture(attacker,victim,serial)
			if serial!=animation_serial: return
		elif mounted:
			await _mounted_capture(attacker,victim,direction.normalized(),serial)
			if serial!=animation_serial: return
		elif str(record.piece).to_lower() in ["p","k"]:
			await _infantry_capture(attacker,victim,direction.normalized(),serial)
			if serial!=animation_serial:return
		else:
			_animate(attacker,"attack")
			sound.play("cloth")
			var royal_role=str(record.piece).to_lower()
			await get_tree().create_timer((.80 if royal_role in ["q","k"] else .44)/_presentation_speed()).timeout
			if serial!=animation_serial: return
			if royal_role=="q":
				var release=_bow_release_point(attacker)
				_held_arrow(attacker,false)
				sound.play("bow")
				await _arrow(release,_capture_target(victim))
			if serial!=animation_serial: return
			if royal_role=="k": _blade_impact(_weapon_contact(attacker,"k"))
			elif royal_role=="p": _impact(_weapon_contact(attacker,"p"),false)
			else: _impact(_capture_target(victim),false)
			if is_instance_valid(victim):
				_victim_hit(victim)
				_animate(victim,"defeat")
				active_tween=_presentation_tween().set_parallel(true)
				if str(record.piece).to_lower()=="r" and str(record.captured).to_lower() in ["p","k","q"]:
					active_tween.tween_property(victim,"position",destination+Vector3(0,1.3,0)-direction.normalized()*.1,.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
					active_tween.tween_property(victim,"rotation:x",-1.2,.7)
					active_tween.tween_property(victim,"position",destination+direction.normalized()*.7+Vector3(0,.10,0),.38).set_delay(.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				else:
					var reaction=InfantryCapture.state(attacker,victim,direction.normalized())
					reaction.victim_rig.player.pause()
					active_tween.tween_method(_defender_recoil.bind(victim,reaction),0.0,1.0,.65)
				await active_tween.finished
				if serial!=animation_serial: return
				active_tween=_presentation_tween(); active_tween.tween_interval(.18)
				await active_tween.finished
				if serial!=animation_serial: return
		if is_instance_valid(victim): victim.visible=false
		active_tween=_presentation_tween(); _travel(active_tween,attacker,destination,_travel_time(attacker,destination,.4))
		await active_tween.finished
		if serial!=animation_serial: return
	else:
		if capture: _animate(attacker,"attack",1.5)
		active_tween=_presentation_tween().set_parallel(true)
		if capture and str(record.piece).to_lower()=="n":
			_travel(active_tween,attacker,destination,.65)
			active_tween.tween_callback(_fast_contact.bind(destination,"n",serial)).set_delay(.58)
		elif capture:
			active_tween.tween_property(attacker,"position",destination,.65).set_trans(Tween.TRANS_SINE)
			active_tween.tween_callback(_fast_contact.bind(destination,str(record.piece).to_lower(),serial)).set_delay(.35)
		else:
			var move_time=_travel_time(attacker,destination,.35)
			# A slightly brisker king leads the castling escort and settles first.
			if cinematic and record.get("castle",false): move_time*=.8
			_travel(active_tween,attacker,destination,move_time)
		if victim:
			victim.set_meta("capture_reaction",0.0)
			active_tween.tween_callback(_fast_reaction.bind(victim,serial)).set_delay(.58 if str(record.piece).to_lower()=="n" else .35)
		if record.get("castle",false):
			if not cinematic: active_tween.tween_callback(_animate.bind(attacker,"idle")).set_delay(.35)
			var elephant: Node3D=pieces[record.rook_from]
			var escort_target=_square_pos(record.rook_to)
			_travel(active_tween,elephant,escort_target,_travel_time(elephant,escort_target,.65))
		await active_tween.finished
		if serial!=animation_serial: return
	if mate:
		sound.play("mate")
		status_label.text=name+" delivers checkmate"
		_animate(attacker,"victory")
		var king_square=game.board.find("K" if game.turn=="w" else "k")
		if pieces.has(king_square):
			var king: Node3D=pieces[king_square]
			var kneel=king.create_tween(); kneel.tween_property(king,"rotation:x",.5,.7)
		await get_tree().create_timer(1.0).timeout
		if serial!=animation_serial: return
	elif record.check:
		sound.play("check")
		_animate(attacker,"threat",1.4)
	if cinematic and capture and not _tutorial_demo():
		active_tween=_presentation_tween()
		active_tween.tween_method(_camera_blend.bind(camera.position,board_camera,camera.quaternion,_look_quat(board_camera,board_look)),0.0,1.0,.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await active_tween.finished
		if serial!=animation_serial: return
	_finish_move()

func _capture_target(victim: Node3D) -> Vector3:
	return victim.position+Vector3(0,1.05 if str(victim.get_meta("piece","")).to_lower() in ["r","n","b"] else .65,0)

func _victim_hit(victim: Node3D) -> void:
	if not is_instance_valid(victim) or victim.get_meta("hit_call_played",false):return
	victim.set_meta("hit_call_played",true)
	sound.animal(str(victim.get_meta("piece","")),"hurt")

func _fast_reaction(victim: Node3D,serial: int) -> void:
	if serial!=animation_serial or not is_instance_valid(victim):return
	_victim_hit(victim)
	victim.set_meta("capture_reaction",1.0);_animate(victim,"defeat",1.5)

func _defender_recoil(p: float,victim: Node3D,state: Dictionary) -> void:
	if is_instance_valid(victim):MountedMotion.defender_reaction(victim,state,p)

func _infantry_capture_frame(t: float,attacker: Node3D,victim: Node3D,state: Dictionary,serial: int) -> void:
	if serial!=animation_serial:return
	InfantryCapture.frame(t,attacker,victim,state)
	if t>=.25 and not state.get("whoosh_done",false):
		state.whoosh_done=true;sound.play("cloth")
	if state.impact and not state.get("impact_done",false):
		state.impact_done=true
		_victim_hit(victim)
		if state.role=="k":_blade_impact(_weapon_contact(attacker,"k"))
		else:_impact(_weapon_contact(attacker,"p"),false)

func _infantry_capture(attacker: Node3D,victim: Node3D,direction: Vector3,serial: int) -> void:
	var state=InfantryCapture.state(attacker,victim,direction)
	attacker.set_meta("capture_state",state)
	active_tween=_presentation_tween();active_tween.tween_method(_infantry_capture_frame.bind(attacker,victim,state,serial),0.0,1.0,1.65)
	await active_tween.finished

func _update_ambient_dust() -> void:
	if ambient_dust:
		ambient_dust.emitting=dust_enabled and theme_index==1
		ambient_dust.visible=dust_enabled and theme_index==1

func _set_dust_enabled(enabled: bool) -> void:
	dust_enabled=enabled;_update_ambient_dust()
	if not enabled:
		for effect in get_tree().get_nodes_in_group("dust_bursts"):effect.queue_free()

func _dust_burst(pos: Vector3,heavy: bool) -> void:
	if not dust_enabled:return
	var dust=DustEffects.emitter(true);world.add_child(dust)
	dust.position=Vector3(pos.x,.1,pos.z);dust.add_to_group("capture_effects");dust.add_to_group("dust_bursts")
	if heavy:dust.scale_amount_max=.48
	get_tree().create_timer(1.1).timeout.connect(dust.queue_free)

func _weapon_contact(node: Node3D,role: String) -> Vector3:
	var rig=HaathiMotion.bind_rig(node)
	var bone: int=rig.bones.hand_r
	# Measured exported spear/royal blade endpoints; effects follow the weapon.
	var local=Vector3(-.01,-.525,-.013) if role=="k" else rig.rest.hand_r.affine_inverse()*Vector3(.331,2.18,.188)
	return rig.skeleton.to_global(rig.skeleton.get_bone_global_pose(bone)*local)

func _fast_contact(pos: Vector3,role: String,serial: int) -> void:
	if serial!=animation_serial: return
	if role in ["k","n","b"]: _blade_impact(pos+Vector3(0,.7,0))
	else: _impact(pos+Vector3(0,.3,0),role=="r")

func _look_quat(pos: Vector3,target: Vector3) -> Quaternion:
	return Basis.looking_at(target-pos,Vector3.UP).get_rotation_quaternion()

func _haathi_capture_frame(t: float,attacker: Node3D,victim: Node3D,state: Dictionary,serial: int) -> void:
	if serial!=animation_serial: return
	HaathiMotion.capture_frame(t,attacker,victim,state)
	if state.impact and not state.get("impact_done",false):
		state.impact_done=true
		_victim_hit(victim)
		_impact(victim.position,true)

func _haathi_capture(attacker: Node3D,victim: Node3D,serial: int) -> void:
	sound.animal("r","attack")
	var infantry=str(victim.get_meta("piece","")).to_lower() in ["p","q"]
	var player=_animation_player(victim)
	if player: player.pause()
	var state=HaathiMotion.capture_state(attacker,victim,infantry)
	attacker.set_meta("capture_state",state)
	active_tween=_presentation_tween()
	active_tween.tween_method(_haathi_capture_frame.bind(attacker,victim,state,serial),0.0,1.0,1.8 if infantry else 1.1)
	await active_tween.finished
	if serial!=animation_serial: return
	await get_tree().create_timer(.12).timeout
	if serial!=animation_serial: return
	victim.visible=false
	HaathiMotion.rest_pose(state.rig)

func _mounted_capture_frame(t: float,attacker: Node3D,victim: Node3D,state: Dictionary,serial: int) -> void:
	if serial!=animation_serial: return
	MountedMotion.capture_frame(t,attacker,victim,state)
	if t>=.24 and not state.get("whoosh_done",false):
		state.whoosh_done=true; sound.play("cloth")
	if state.impact and not state.get("impact_done",false):
		state.impact_done=true
		_victim_hit(victim)
		_blade_impact(state.contact_point)

func _mounted_capture(attacker: Node3D,victim: Node3D,direction: Vector3,serial: int) -> void:
	var state=MountedMotion.capture_state(attacker,victim,direction)
	attacker.set_meta("capture_state",state)
	active_tween=_presentation_tween()
	active_tween.tween_method(_mounted_capture_frame.bind(attacker,victim,state,serial),0.0,1.0,MountedMotion.DURATION)
	await active_tween.finished
	if serial!=animation_serial: return
	victim.visible=false

func _camera_blend(t: float, start: Vector3, target: Vector3, start_q: Quaternion,target_q: Quaternion) -> void:
	camera.position=start.lerp(target,t); camera.quaternion=start_q.slerp(target_q,t)
	_update_court_visibility()

func _update_court_visibility() -> void:
	if not court or not camera: return
	var direction=Vector3(camera.position.x,0,camera.position.z).normalized()
	for boundary in court.get_children():
		if boundary.has_meta("boundary_origin"):
			var origin: Vector3=boundary.get_meta("boundary_origin")
			boundary.visible=origin.normalized().dot(direction)<=.12

func _arrow(a: Vector3,b: Vector3) -> void:
	var arrow:=Node3D.new(); world.add_child(arrow)
	arrow.name="RoyalProjectile"
	arrow.add_to_group("capture_effects")
	var shaft:=MeshInstance3D.new(); var mesh:=CylinderMesh.new()
	mesh.top_radius=.013; mesh.bottom_radius=.013; mesh.height=.62
	shaft.mesh=mesh; shaft.material_override=_mat(GOLD,.5); arrow.add_child(shaft)
	var tip:=MeshInstance3D.new(); var tip_mesh:=PrismMesh.new(); tip_mesh.size=Vector3(.08,.13,.025)
	tip.mesh=tip_mesh; tip.material_override=_mat(LIGHT,.4); tip.position.y=.35; arrow.add_child(tip)
	arrow.position=a; arrow.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	var flight_time=.48 if _tutorial_demo() else .22
	var flight=arrow.create_tween(); flight.tween_property(arrow,"position",b,flight_time)
	await get_tree().create_timer(flight_time).timeout
	if is_instance_valid(arrow): arrow.queue_free()

func _blade_impact(pos: Vector3) -> void:
	sound.play("blade");_dust_burst(pos,false)
	# Brief flecks at the actual blade contact, with no floating ground ripple.
	for i in range(5):
		var spark:=MeshInstance3D.new(); var mesh:=SphereMesh.new()
		mesh.radius=.009; mesh.height=.018; mesh.radial_segments=6; mesh.rings=3
		spark.mesh=mesh; spark.material_override=_mat(Color("c5b390"),.6)
		spark.position=pos; world.add_child(spark); spark.add_to_group("capture_effects")
		var angle=TAU*i/5.0
		var flight=spark.create_tween().set_parallel(true)
		flight.tween_property(spark,"position",pos+Vector3(cos(angle)*.12,.06-i*.025,sin(angle)*.12),.22)
		flight.tween_property(spark,"scale",Vector3.ZERO,.22)
		flight.chain().tween_callback(spark.queue_free)

func _impact(pos: Vector3,heavy: bool) -> void:
	sound.play("heavy" if heavy else "hit")
	_dust_burst(pos,heavy)

func _clear_effects() -> void:
	if sound: sound.stop_all()
	for effect in get_tree().get_nodes_in_group("capture_effects"): effect.queue_free()

func _finish_move() -> void:
	if not last_move.is_empty():
		var heading=_square_pos(last_move.to)-_square_pos(last_move.from)
		facing_by_square.erase(last_move.from)
		facing_by_square[last_move.to]=atan2(heading.x,heading.z)
		if str(last_move.piece).to_lower()=="n" and last_move.captured=="":
			var final_leg=Vector3(0,0,heading.z) if absf(heading.x)>absf(heading.z) else Vector3(heading.x,0,0)
			facing_by_square[last_move.to]=atan2(final_leg.x,final_leg.z)
		if last_move.get("castle",false):
			var escort=_square_pos(last_move.rook_to)-_square_pos(last_move.rook_from)
			facing_by_square.erase(last_move.rook_from)
			facing_by_square[last_move.rook_to]=atan2(escort.x,escort.z)
	busy=false; skip_button.visible=false
	if not is_instance_valid(training) or training.phase!="demo":
		camera.position=board_camera; camera.look_at(board_look)
	_update_court_visibility()
	_sync_pieces(); _update_ui()
	if is_instance_valid(training):training.move_finished()
	if game.outcome()=="checkmate" and not last_move.is_empty():
		_animate(pieces[last_move.to],"victory")
		var king=game.board.find("K" if game.turn=="w" else "k")
		if pieces.has(king): pieces[king].rotation.x=.4

func _skip() -> void:
	if not busy: return
	animation_serial+=1
	if active_tween and active_tween.is_running(): active_tween.kill()
	_clear_effects()
	_finish_move()

func _new_game(demo := false) -> void:
	if computer:
		computer.cancel()
		if demo:computer.enabled=false
	_end_intro()
	animation_serial+=1
	if active_tween and active_tween.is_running(): active_tween.kill()
	_clear_effects()
	game=Rules.new("4k3/7p/8/8/8/8/P2R2p1/K7 w - - 0 1" if demo else "")
	busy=false; ended=false; selected=-1; notation=[]; last_move={}
	facing_by_square.clear()
	promotion_panel.visible=false; skip_button.visible=false
	camera.position=board_camera; camera.look_at(board_look)
	_update_court_visibility()
	_sync_pieces(); _update_ui()
	if demo:
		pieces[11].rotation.y=PI/2; pieces[14].rotation.y=-PI/2
		_select(11); sub_label.text="Capture study · select Haathi on d2, then Pyada on g2"
		camera.position=Vector3(1.0,3.4,8.2); camera.look_at(Vector3(1,.95,2.5))
		_update_court_visibility()

func _undo() -> void:
	if computer:computer.cancel()
	_end_intro()
	_clear_effects()
	if busy: _skip()
	if game.undo():
		if computer and computer.enabled and game.turn!=computer.human_side and not game.history.is_empty():
			game.undo()
			if not notation.is_empty():notation.pop_back()
		facing_by_square.clear()
		if not notation.is_empty(): notation.pop_back()
		ended=false; last_move={}; selected=-1; promotion_panel.visible=false
		_sync_pieces(); _update_ui()

func _walk_study() -> void:
	_new_game(true)
	game=Rules.new("4k3/7p/8/8/8/8/P2R4/K7 w - - 0 1")
	_sync_pieces(); _update_ui()
	pieces[11].rotation.y=PI
	# A normal legal rook move, shown from a low profile view for foot contact.
	camera.position=Vector3(1,2.3,7.0); camera.look_at(Vector3(1,.75,2.5))
	_update_court_visibility()
	_make_move(11,14)

func _royal_walk_study(role: String) -> void:
	_new_game(true)
	game=Rules.new("7k/8/8/8/8/8/3Q4/K7 w - - 0 1" if role=="q" else "7k/7p/8/8/8/8/3K4/8 w - - 0 1")
	_sync_pieces();_update_ui()
	var target=38 if role=="q" else 20
	var focus=(_square_pos(11)+_square_pos(target))*.5+Vector3(0,.6,0)
	camera.position=focus+Vector3(3.5,2.0,4.8);camera.look_at(focus);_update_court_visibility()
	_make_move(11,target)
	sub_label.text=NAMES[role]+" footwork · alternating support, knee lift and settled arrival."

func _pyada_study() -> void:
	_new_game(true)
	game=Rules.new("7k/8/8/8/8/4p3/3P4/K7 w - - 0 1")
	_sync_pieces(); _update_ui()
	pieces[20].rotation.y=-PI/4
	camera.position=Vector3(2.5,2.0,5.2); camera.look_at(Vector3(0,.7,2.0))
	_update_court_visibility()
	_select(11)
	sub_label.text="Infantry study · move d2 to d3, or capture on e3."

func _pyada_portrait() -> void:
	_new_game(true)
	game=Rules.new("7k/8/8/8/8/8/3P4/K7 w - - 0 1")
	_sync_pieces(); _update_ui()
	pieces[11].rotation.y=-.12
	camera.position=Vector3(-.20,1.43,3.70)
	camera.look_at(Vector3(-.5,1.13,2.5)); _update_court_visibility()
	status_label.text="The spear soldier"
	sub_label.text="A closer look at the Pyada."
	selection_label.text="Face and fabric"
	hint_label.text="New game returns to the full army."

func _mounted_study() -> void:
	_new_game(true)
	game=Rules.new("7k/8/8/8/8/8/1R1N1B2/K7 w - - 0 1")
	_sync_pieces(); _update_ui()
	for square in [9,11,13]: pieces[square].rotation.y=-.18
	camera.position=Vector3(1.1,2.7,8.2)
	camera.look_at(Vector3(-.5,.95,2.5)); _update_court_visibility()
	status_label.text="The royal mounts"
	sub_label.text="Haathi, Ghoda and Oont · choose a piece to move."
	selection_label.text="Hide, cloth and steel"
	hint_label.text="New game returns to the full army."

func _mount_portrait(role: String,black: bool=false) -> void:
	_new_game(true)
	var piece=role if black else role.to_upper()
	var far_rank="8" if role=="k" and black else "7k"
	var near_rank="8" if role=="k" and not black else "K7"
	game=Rules.new(far_rank+"/8/8/8/8/8/3"+piece+"4/"+near_rank+" w - - 0 1")
	_sync_pieces(); _update_ui(); _clear_markers()
	pieces[11].rotation.y=-.30
	var focus=_square_pos(11)+Vector3(0,.86,0)
	camera.position=focus+Vector3(1.55,.40,2.55); camera.look_at(focus); _update_court_visibility()
	status_label.text="The royal "+NAMES[role]
	sub_label.text="Sculpted anatomy, fitted steel and layered riding armour."
	if role in ["q","k"]: sub_label.text="Royal silk, gold embroidery and jewelled regalia."
	if role=="k": sub_label.text="Mughal-inspired jewelled cap, plume and woven mantle." if black else "Wrapped turban, jewelled ornament and woven mantle."
	elif role=="q": sub_label.text="Embroidered sash, fine jewellery and moving cloth panels."
	selection_label.text="Saffron" if not black else "Emerald"
	hint_label.text="Try the encounter study to see this rider in action."
	if role in ["q","k"]: hint_label.text="New game returns to the full army."

func _encounter_study(role: String) -> void:
	_new_game(true)
	var horse=role=="n"
	game=Rules.new("7k/8/8/8/4p3/8/3N4/K7 w - - 0 1" if horse else "7k/8/8/2p5/8/8/5B2/K7 w - - 0 1")
	_sync_pieces(); _update_ui()
	_select(11 if horse else 13)
	status_label.text="Ghoda encounter" if horse else "Oont encounter"
	sub_label.text="Capture the Pyada on e4." if horse else "Capture the Pyada on c5."
	hint_label.text="Cinematic mode shows the rider's approach, strike and recovery."

func _haathi_portrait() -> void:
	_new_game(true)
	game=Rules.new("7k/8/8/8/8/8/3R4/K7 w - - 0 1")
	_sync_pieces(); _update_ui()
	pieces[11].rotation.y=-.28
	var focus=_square_pos(11)+Vector3(0,1.08,0)
	camera.position=focus+Vector3(1.25,.30,2.75)
	camera.look_at(focus); _update_court_visibility()
	status_label.text="The royal Haathi"
	sub_label.text="Living hide, grounded limbs and ceremonial armour."
	selection_label.text="The elephant portrait"
	hint_label.text="Choose Haathi to move, or New game for the full army."

func _royal_encounter(role: String) -> void:
	_new_game(true)
	game=Rules.new("7k/8/8/8/3p4/8/3Q4/K7 w - - 0 1" if role=="q" else "7k/8/8/8/8/3p4/3K4/8 w - - 0 1")
	_sync_pieces(); _update_ui(); _select(11)
	status_label.text=NAMES[role]+" encounter"
	sub_label.text="Capture the Pyada on d4." if role=="q" else "Capture the Pyada on d3."
	hint_label.text="Cinematic mode shows the bow draw and release." if role=="q" else "Cinematic mode shows the guard, strike and recovery."
	var focus=(_square_pos(11)+_square_pos(27 if role=="q" else 19))*.5+Vector3(0,.8,0)
	camera.position=focus+Vector3(3.5,2.3,4.0); camera.look_at(focus); _update_court_visibility()

func _haathi_face() -> void:
	_haathi_portrait()
	var focus=_square_pos(11)+Vector3(0,1.23,0)
	camera.position=focus+Vector3(.55,.10,1.75)
	camera.look_at(focus); _update_court_visibility()
	selection_label.text="The warrior's gaze"
	sub_label.text="A closer look at the sculpted brow and eyes."

func _armour_study() -> void:
	_new_game(true)
	game=Rules.new("7k/8/8/8/1r1n1b2/8/1R1N1B2/K7 w - - 0 1")
	_sync_pieces(); _update_ui()
	for square in [9,11,13,25,27,29]: pieces[square].rotation.y=-.35
	camera.position=Vector3(2.4,4.4,8.8)
	camera.look_at(Vector3(-.5,.8,1.5)); _update_court_visibility()
	status_label.text="Saffron & Emerald"
	sub_label.text="Painted war armour · natural hide and fur."
	selection_label.text="Two armies, clear colours"
	hint_label.text="Choose a piece to inspect its legal moves."

func _flip() -> void:
	if busy: return
	flipped=not flipped
	_set_view(wrapf(view_yaw+180.0,-180.0,180.0),view_tilt,view_distance)

func _set_view(yaw: float,tilt: float,distance: float) -> void:
	view_yaw=wrapf(yaw,-180.0,180.0)
	view_tilt=clampf(tilt,15.0,88.0)
	view_distance=clampf(distance,2.8,26.0)
	var y=deg_to_rad(view_yaw); var elevation=deg_to_rad(view_tilt)
	board_camera=board_look+Vector3(sin(y)*cos(elevation),sin(elevation),cos(y)*cos(elevation))*view_distance
	if rotate_slider: rotate_slider.set_value_no_signal(view_yaw)
	if tilt_slider: tilt_slider.set_value_no_signal(view_tilt)
	if zoom_slider: zoom_slider.set_value_no_signal(view_distance)
	# Changing a view during a capture finishes that presentation first.
	# The already-committed move is preserved and the new viewpoint wins.
	if intro_active: _end_intro()
	if busy: _skip()
	camera.position=board_camera; camera.look_at(board_look)
	_update_court_visibility()

func _view_preset(preset: String) -> void:
	board_look=Vector3(0,.1,0)
	match preset:
		"front":
			board_look=Vector3(0,.65,0)
			_set_view(180.0 if flipped else 0.0,48.0 if is_instance_valid(mobile_layout) and mobile_layout.compact else 22.0,13.5 if is_instance_valid(mobile_layout) and mobile_layout.compact else 14.5)
		"angled": _set_view(-146.0 if flipped else 34.0,40.0,17.5)
		"top": _set_view(180.0 if flipped else 0.0,88.0,16.0)

func _focus_selected() -> void:
	if selected<0:
		hint_label.text="Select a piece, then Focus selected. Scroll or use Distance to zoom."
		return
	board_look=_square_pos(selected)+Vector3(0,.8,0)
	_set_view(view_yaw,22,4.2)

func _change_theme(index: int) -> void:
	theme_index=index
	if theme_selector: theme_selector.select(index)
	court.visible=index==0; battlefield.visible=index==1
	var colors=["536376","27313f"] if index==0 else ["716c56","343c32"]
	var mats=[_stone(Color(colors[0])),_stone(Color(colors[1]))]
	for square in range(64):
		tiles[square].material_override=mats[0 if (square%8+square/8)%2==1 else 1]
	var frame_colors=["100f18","bb8a43","241b24","d8ad64"] if index==0 else ["403c33","6c604b","514c40","837961"]
	for i in range(board_frame.size()): board_frame[i].material_override=_mat(Color(frame_colors[i]),.15) if index==0 else _stone(Color(frame_colors[i]))
	scene_environment.background_mode=Environment.BG_COLOR if index==0 else Environment.BG_SKY
	scene_environment.background_color=Color("080d17") if index==0 else Color("9a9c90")
	scene_environment.fog_density=.009 if index==0 else .002
	scene_environment.fog_light_color=Color("29252a") if index==0 else Color("a6a28f")
	scene_environment.ambient_light_energy=.46 if index==0 else .48
	scene_environment.ambient_light_color=Color("b9c5d1") if index==0 else Color("9caec4")
	var sunlight:=world.get_node("BattleSun") as DirectionalLight3D
	sunlight.rotation_degrees=Vector3(-52,-28,0) if index==0 else Vector3(-34,-38,0)
	sunlight.light_color=Color("fff1dc") if index==0 else Color("ffe0b5")
	sunlight.light_energy=.75 if index==0 else 1.02
	sunlight.shadow_opacity=.55 if index==0 else .72
	_update_ambient_dust()

func _view_slider(parent: VBoxContainer,title: String,minimum: float,maximum: float,value: float,callback: Callable) -> HSlider:
	var row:=HBoxContainer.new(); parent.add_child(row)
	var text=_label(title,14,MUTED); text.custom_minimum_size.x=60; row.add_child(text)
	var slider:=HSlider.new(); slider.min_value=minimum; slider.max_value=maximum; slider.step=.5
	slider.scrollable=false # Scrolling the study menu must not alter the camera sliders.
	slider.value=value; slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size=Vector2(0,30); row.add_child(slider)
	slider.value_changed.connect(callback); return slider

func _ask_promotion(a: int,b: int) -> void:
	promotion_panel.visible=true
	for child in promotion_panel.get_children(): child.queue_free()
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",12); promotion_panel.add_child(box)
	box.add_child(_label("Choose your promotion",22,LIGHT))
	for type in ["q","r","b","n"]:
		var btn=_button(NAMES[type],func(): promotion_panel.visible=false; _make_move(a,b,type))
		box.add_child(btn)
	box.add_child(_button("Cancel",func(): promotion_panel.visible=false))

func _claim_draw() -> void:
	if not busy and game.claimable_draw()!="":
		ended=true; status_label.text="Draw agreed by rule"; sub_label.text=game.claimable_draw().replace("_"," ").capitalize()

func _update_ui() -> void:
	if is_instance_valid(mobile_layout):mobile_layout.refresh()
	var result=game.outcome()
	ended=result!=""
	var side_name="Saffron" if game.turn=="w" else "Emerald"
	turn_label.text=side_name.to_upper()+" TO MOVE"
	status_label.text=side_name+" to move"
	sub_label.text=("You: "+("Saffron / White" if computer.human_side=="w" else "Emerald / Black")+" · Stockfish Level "+str(computer.level)) if computer and computer.enabled and not is_instance_valid(training) else "A royal game. A living battlefield."
	check_label.text="CHECK — protect your Raja" if game.in_check() else ""
	if ended:
		status_label.text=("Emerald" if game.turn=="w" else "Saffron")+" wins" if result=="checkmate" else "Draw"
		sub_label.text=result.replace("_"," ").capitalize()
	selection_label.text="Choose your piece"
	hint_label.text="Tap a piece, then a highlighted square."
	move_list.clear()
	if notation.is_empty(): move_list.append_text("[color=#94aaa9]Your story begins with the first move.[/color]")
	for i in range(notation.size()):
		move_list.append_text("[color=#879e9c]"+str(i/2+1)+(". " if i%2==0 else "… ")+"[/color] "+notation[i]+"\n\n")
	var captures: Array[String]=[]
	for record in game.history:
		if record.captured!="": captures.append(NAMES[str(record.captured).to_lower()])
	capture_label.text=" · ".join(captures) if not captures.is_empty() else "No pieces captured"

func _label(text: String,size: int,color: Color) -> Label:
	var label:=Label.new(); label.text=text; label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color); label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return label

func _style(bg: Color,border: Color,radius := 6) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new(); s.bg_color=bg; s.border_color=border
	s.set_border_width_all(1); s.set_corner_radius_all(radius)
	s.content_margin_left=18; s.content_margin_right=18; s.content_margin_top=12; s.content_margin_bottom=12
	return s

func _button(text: String,callback: Callable) -> Button:
	var b:=Button.new(); b.text=text; b.custom_minimum_size=Vector2(0,46)
	b.add_theme_font_size_override("font_size",16)
	b.add_theme_color_override("font_color",LIGHT)
	b.add_theme_stylebox_override("normal",_style(Color("162b2d"),Color("34504e")))
	b.add_theme_stylebox_override("hover",_style(Color("264641"),GOLD))
	b.add_theme_stylebox_override("pressed",_style(Color("315d53"),GOLD))
	b.pressed.connect(callback); return b

func _sidebar_page(title: String) -> VBoxContainer:
	var scroll=ScrollContainer.new(); scroll.name=title
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; sidebar_tabs.add_child(scroll)
	var content=VBoxContainer.new(); content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",12); scroll.add_child(content)
	return content

func _set_developer_mode(enabled: bool) -> void:
	developer_mode=enabled
	if not enabled and sidebar_tabs.current_tab==2: sidebar_tabs.current_tab=0
	sidebar_tabs.set_tab_hidden(2,not enabled)
	mode_selector.select(1 if enabled else 0)

func _build_ui() -> void:
	var layer:=CanvasLayer.new(); add_child(layer)
	var ui:=Control.new();game_ui=ui; ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter=Control.MOUSE_FILTER_IGNORE; layer.add_child(ui)
	var top:=MarginContainer.new();ui_top=top; top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom=94; top.add_theme_constant_override("margin_left",34); top.add_theme_constant_override("margin_right",32)
	top.add_theme_constant_override("margin_top",20); ui.add_child(top)
	var row:=HBoxContainer.new(); top.add_child(row)
	var titlebox:=VBoxContainer.new(); titlebox.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(titlebox)
	var title=_label("SHATRANJ",36,GOLD)
	var serif:=SystemFont.new(); serif.font_names=PackedStringArray(["Georgia","Noto Serif"])
	title.add_theme_font_override("font",serif); titlebox.add_child(title)
	titlebox.add_child(_label("T H E   R O Y A L   B A T T L E F I E L D",13,MUTED))
	var badge:=VBoxContainer.new(); row.add_child(badge)
	badge.add_child(_label("LOCAL TWO-PLAYER",14,LIGHT))
	piece_badges=preload("res://scripts/piece_badges.gd").new(); piece_badges.game_view=self
	piece_badges.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(piece_badges); piece_badges.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	piece_badges.anchor_right=.76; piece_badges.anchor_top=.09; piece_badges.anchor_bottom=.96

	var side:=PanelContainer.new();ui_side=side; side.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	side.anchor_left=.755; side.offset_left=0; side.offset_right=-26; side.offset_top=108; side.offset_bottom=-42
	side.add_theme_stylebox_override("panel",_style(Color("102326"),Color("2b4645"),12)); ui.add_child(side)
	var shell:=VBoxContainer.new(); side.add_child(shell)
	mode_selector=OptionButton.new(); mode_selector.add_item("Player mode"); mode_selector.add_item("Developer mode")
	mode_selector.custom_minimum_size.y=42; mode_selector.add_theme_font_size_override("font_size",16)
	mode_selector.item_selected.connect(func(index): _set_developer_mode(index==1)); shell.add_child(mode_selector)
	sidebar_tabs=TabContainer.new(); sidebar_tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL; shell.add_child(sidebar_tabs)
	sidebar_tabs.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	sidebar_tabs.add_theme_font_size_override("font_size",14)
	for state in ["tab_selected","tab_unselected","tab_hovered"]:
		var tab_style=StyleBoxFlat.new(); tab_style.bg_color=Color("29453f") if state=="tab_selected" else Color("142b2c")
		tab_style.content_margin_left=8;tab_style.content_margin_right=8;tab_style.content_margin_top=10;tab_style.content_margin_bottom=10
		tab_style.set_corner_radius_all(5); sidebar_tabs.add_theme_stylebox_override(state,tab_style)
	sidebar_tabs.add_theme_color_override("font_selected_color",GOLD)
	var box=_sidebar_page("Match")
	var view_box=_sidebar_page("View")
	var study_box=_sidebar_page("Studies")
	var learn_box=_sidebar_page("Learn")
	learn_box.add_child(_button("Learn Chess",_show_academy))
	learn_box.add_child(_button("Browse tactics lessons",_show_academy))
	study_box.add_child(_label("DEVELOPER STUDIES",14,GOLD))
	var study_note=_label("Study buttons reset the board to a test position.",15,MUTED)
	study_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; study_box.add_child(study_note)
	view_box.add_child(HSeparator.new()); view_box.add_child(_label("BOARD VIEW",14,GOLD))
	var camera_help=_label("Scroll / Distance: zoom. Middle-drag: pan. Front: reset view.",14,MUTED); camera_help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; view_box.add_child(camera_help)
	var views:=HBoxContainer.new(); view_box.add_child(views)
	for preset in ["front","angled","top"]:
		var btn=_button("Overhead" if preset=="top" else str(preset).capitalize(),_view_preset.bind(preset))
		btn.add_theme_font_size_override("font_size",14)
		var compact=_style(Color("162b2d"),Color("34504e"))
		compact.content_margin_left=7; compact.content_margin_right=7
		btn.add_theme_stylebox_override("normal",compact)
		btn.size_flags_horizontal=Control.SIZE_EXPAND_FILL; views.add_child(btn)
	rotate_slider=_view_slider(view_box,"Rotate",-180,180,view_yaw,func(v): _set_view(v,view_tilt,view_distance))
	tilt_slider=_view_slider(view_box,"Tilt",15,88,view_tilt,func(v): _set_view(view_yaw,v,view_distance))
	zoom_slider=_view_slider(view_box,"Distance",2.8,26,view_distance,func(v): _set_view(view_yaw,view_tilt,v))
	view_box.add_child(_button("Focus selected",_focus_selected))
	var themes=OptionButton.new(); theme_selector=themes; themes.add_item("Palace"); themes.add_item("Battlefield")
	themes.custom_minimum_size.y=42; themes.item_selected.connect(_change_theme)
	view_box.add_child(_label("ENVIRONMENT",14,GOLD)); view_box.add_child(themes)
	var badges=CheckButton.new(); badges.text="Piece icons"; badges.button_pressed=true
	badges.tooltip_text="Rook = Haathi, bishop = Oont, knight = Ghoda. Select a piece for its name."
	badges.toggled.connect(func(on): piece_badges.enabled=on); view_box.add_child(badges)
	badge_opacity_slider=_view_slider(view_box,"Opacity",.1,1,.55,func(value): piece_badges.opacity=value)
	badge_opacity_slider.step=.05; badge_opacity_slider.set_value_no_signal(.55)
	turn_label=_label("",14,GOLD); box.add_child(turn_label)
	status_label=_label("",27,LIGHT); status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(status_label)
	sub_label=_label("",15,MUTED); sub_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(sub_label)
	check_label=_label("",16,Color("f19877")); check_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(check_label)
	box.add_child(HSeparator.new())
	selection_label=_label("",19,LIGHT); box.add_child(selection_label)
	hint_label=_label("",15,MUTED); hint_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(hint_label)
	var cinema:=CheckButton.new(); cinema.text="Cinematic captures"; cinema.button_pressed=true
	cinema.add_theme_font_size_override("font_size",16); cinema.toggled.connect(func(on): cinematic=on); view_box.add_child(cinema)
	skip_button=_button("Skip animation",_skip); box.add_child(skip_button); skip_button.visible=false
	var opening:=CheckButton.new(); opening.text="Opening tour"; opening.button_pressed=intro_enabled
	opening.add_theme_font_size_override("font_size",16)
	opening.toggled.connect(_toggle_intro)
	view_box.add_child(opening)
	var audio_row:=HBoxContainer.new(); view_box.add_child(audio_row)
	var mute:=CheckButton.new(); mute.text="Mute all"; mute.button_pressed=sound.muted
	mute.toggled.connect(sound.set_muted); audio_row.add_child(mute)
	var volume:=HSlider.new(); volume.min_value=0; volume.max_value=1; volume.step=.05
	volume.value=sound.volume; volume.custom_minimum_size.x=110; volume.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	volume.tooltip_text="Effects volume"; volume.value_changed.connect(sound.set_volume); audio_row.add_child(volume)
	view_box.add_child(HSeparator.new());view_box.add_child(_label("ATMOSPHERE",14,GOLD))
	var music=CheckButton.new();music.text="Background music";music.button_pressed=sound.music_enabled
	music.toggled.connect(sound.set_music_enabled);view_box.add_child(music)
	var music_level=_view_slider(view_box,"Music",0,1,sound.music_volume,sound.set_music_volume)
	music_level.step=.05;music_level.set_value_no_signal(sound.music_volume)
	var dust=CheckButton.new();dust.text="Dust effects";dust.button_pressed=dust_enabled
	dust.toggled.connect(_set_dust_enabled);view_box.add_child(dust)
	box.add_child(_button("Home",_show_home))
	box.add_child(_button("New game",func(): _new_game()))
	var controls:=HBoxContainer.new(); box.add_child(controls)
	var undo=_button("Undo",_undo); undo.size_flags_horizontal=Control.SIZE_EXPAND_FILL; controls.add_child(undo)
	var flip=_button("Turn board",_flip); flip.size_flags_horizontal=Control.SIZE_EXPAND_FILL; controls.add_child(flip)
	box.add_child(HSeparator.new()); box.add_child(_label("MOVE CHRONICLE",14,GOLD))
	move_list=RichTextLabel.new(); move_list.bbcode_enabled=true; move_list.custom_minimum_size=Vector2(0,135)
	move_list.add_theme_font_size_override("normal_font_size",15); move_list.scroll_following=true; box.add_child(move_list)
	box.add_child(_label("CAPTURED",13,MUTED))
	capture_label=_label("",14,LIGHT); capture_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(capture_label)
	box.add_child(HSeparator.new())
	study_box.add_child(_button("Haathi encounter",func(): _new_game(true)))
	study_box.add_child(_button("Haathi walk study",_walk_study))
	study_box.add_child(_button("Ghoda jump",_knight_study))
	study_box.add_child(_button("Raja footwork",_royal_walk_study.bind("k")))
	study_box.add_child(_button("Rani footwork",_royal_walk_study.bind("q")))
	study_box.add_child(_button("Haathi portrait",_haathi_portrait))
	study_box.add_child(_button("Haathi face",_haathi_face))
	study_box.add_child(_button("Pyada study",_pyada_study))
	study_box.add_child(_button("Pyada portrait",_pyada_portrait))
	study_box.add_child(_button("Royal mounts",_mounted_study))
	study_box.add_child(_button("Ghoda portrait",_mount_portrait.bind("n")))
	study_box.add_child(_button("Oont portrait",_mount_portrait.bind("b")))
	study_box.add_child(_button("Rani portrait",_mount_portrait.bind("q")))
	study_box.add_child(_button("Raja portrait",_mount_portrait.bind("k")))
	study_box.add_child(_button("Emerald Raja portrait",_mount_portrait.bind("k",true)))
	study_box.add_child(_button("Rani encounter",_royal_encounter.bind("q")))
	study_box.add_child(_button("Raja encounter",_royal_encounter.bind("k")))
	study_box.add_child(_button("Ghoda encounter",_encounter_study.bind("n")))
	study_box.add_child(_button("Oont encounter",_encounter_study.bind("b")))
	study_box.add_child(_button("Armour colours",_armour_study))
	box.add_child(_button("Claim draw",_claim_draw))
	var fps:=CheckButton.new(); fps.text="60 FPS"; fps.toggled.connect(func(on): Engine.max_fps=60 if on else 30); view_box.add_child(fps)
	box.add_child(_button("Credits",_credits))
	var bottom:=MarginContainer.new();ui_bottom=bottom; bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top=-38; bottom.offset_left=34; bottom.offset_right=-30; ui.add_child(bottom)
	bottom.add_child(_label("HAATHI · OONT · GHODA · RANI · RAJA · PYADA     /     Standard chess. Extraordinary battles.",13,MUTED))
	promotion_panel=PanelContainer.new(); ui.add_child(promotion_panel)
	promotion_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER); promotion_panel.offset_left=-180; promotion_panel.offset_right=180
	promotion_panel.offset_top=-200; promotion_panel.offset_bottom=200
	promotion_panel.add_theme_stylebox_override("panel",_style(INK,GOLD,12)); promotion_panel.visible=false
	intro_panel=PanelContainer.new(); ui.add_child(intro_panel)
	intro_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_panel.anchor_left=.025; intro_panel.anchor_right=.735
	intro_panel.anchor_top=.79; intro_panel.anchor_bottom=.935
	intro_panel.add_theme_stylebox_override("panel",_style(Color("101923ee"),GOLD,9))
	var intro_row:=VBoxContainer.new(); intro_row.add_theme_constant_override("separation",6); intro_panel.add_child(intro_row)
	var factions:=HBoxContainer.new(); intro_row.add_child(factions)
	var red_side=_label("RED CAMP",13,Color("e4958b")); red_side.size_flags_horizontal=Control.SIZE_EXPAND_FILL; factions.add_child(red_side)
	var green_side=_label("GREEN CAMP",13,Color("8dc6a5")); green_side.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; factions.add_child(green_side)
	var captions:=VBoxContainer.new(); captions.size_flags_horizontal=Control.SIZE_EXPAND_FILL; intro_row.add_child(captions)
	intro_title=_label("Meet your army",20,GOLD); captions.add_child(intro_title)
	intro_subtitle=_label("",14,LIGHT); intro_subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; captions.add_child(intro_subtitle)
	intro_progress=ProgressBar.new(); intro_progress.custom_minimum_size.y=4; intro_progress.show_percentage=false
	var fill:=StyleBoxFlat.new(); fill.bg_color=GOLD; fill.set_corner_radius_all(2)
	var track:=StyleBoxFlat.new(); track.bg_color=Color("253544"); track.set_corner_radius_all(2)
	intro_progress.add_theme_stylebox_override("fill",fill)
	intro_progress.add_theme_stylebox_override("background",track)
	captions.add_child(intro_progress)
	var skip_intro=_button("Skip intro ›",_end_intro); skip_intro.name="SkipIntro"; skip_intro.custom_minimum_size=Vector2(110,44); skip_intro.size_flags_horizontal=Control.SIZE_SHRINK_END; skip_intro.add_theme_font_size_override("font_size",14)
	for state in ["normal","hover","pressed"]:
		var skip_style=skip_intro.get_theme_stylebox(state).duplicate(); skip_style.content_margin_top=4; skip_style.content_margin_bottom=4; skip_style.content_margin_left=12; skip_style.content_margin_right=12; skip_intro.add_theme_stylebox_override(state,skip_style)
	intro_row.add_child(skip_intro)
	intro_panel.visible=false
	mobile_layout=preload("res://scripts/mobile_layout.gd").new();mobile_layout.app=self;add_child(mobile_layout)
	get_viewport().size_changed.connect(_responsive)
	_responsive()
	_view_preset("front")
	_set_developer_mode(false)

func _credits() -> void:
	var dialog:=AcceptDialog.new(); dialog.title="Shatranj · Credits"
	dialog.dialog_text="Models and skeletal animation developed in Blender. Rani face and upper hair adapted from the user-provided ChessPieces sculpt.\nOriginal hide, cloth, leather and metal surfaces.\nOriginal foley; animal calls: BigSoundBank, Wikimedia Commons and OpenGameArt (public domain / CC0). See AUDIO_CREDITS.txt.\nBuilt with Godot Engine, distributed under the MIT license.\nGodot copyright and license: https://godotengine.org/license/\n\nVersion 1.1 · Local two-player chess."
	add_child(dialog); dialog.popup_centered(Vector2i(560,240)); dialog.confirmed.connect(dialog.queue_free)

func _configure_display() -> bool:
	var target:=Vector2i.ZERO
	if OS.has_feature("web"):
		var dimensions=JavaScriptBridge.eval("[window.innerWidth,window.innerHeight].join(',')")
		if dimensions is String:
			var parts=dimensions.split(",")
			if parts.size()==2:target=Vector2i(int(parts[0]),int(parts[1]))
	elif OS.has_feature("android"):
		var density:=maxf(1.0,DisplayServer.screen_get_dpi()/160.0)
		target=Vector2i(Vector2(get_window().size)/density)
	if target.x>0 and target.y>0 and get_window().content_scale_size!=target:
		get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		get_window().content_scale_size=target
		return true
	return false

func _responsive() -> void:
	if _configure_display():call_deferred("_responsive");return
	if is_instance_valid(mobile_layout):mobile_layout.layout()
	if is_instance_valid(training):training.layout()
	if is_instance_valid(home_menu):home_menu.layout()


func _qa_sequence() -> void:
	await get_tree().create_timer(2).timeout
	get_viewport().get_texture().get_image().save_png("user://board.png")
	_new_game(true)
	await get_tree().create_timer(.4).timeout
	get_viewport().get_texture().get_image().save_png("user://stone-encounter.png")
	_make_move(11,14)
	await get_tree().create_timer(3.6).timeout
	get_viewport().get_texture().get_image().save_png("user://capture_contact.png")
	await get_tree().create_timer(.45).timeout
	get_viewport().get_texture().get_image().save_png("user://capture.png")
	await get_tree().create_timer(.5).timeout
	get_viewport().get_texture().get_image().save_png("user://capture_release.png")
	for i in range(100):
		if not busy: break
		await get_tree().create_timer(.1).timeout
	get_viewport().get_texture().get_image().save_png("user://capture_complete.png")
	print("QA_CAPTURE_COMPLETE ",game.fen()," busy=",busy," models=",assets.size())
	get_tree().quit()

func _qa_walk_sequence() -> void:
	await get_tree().create_timer(.5).timeout
	_walk_study()
	for i in range(8):
		await get_tree().create_timer(.38).timeout
		get_viewport().get_texture().get_image().save_png("user://walk-%02d.png" % i)
	for i in range(80):
		if not busy: break
		await get_tree().create_timer(.1).timeout
	get_viewport().get_texture().get_image().save_png("user://walk_complete.png")
	print("QA_WALK_COMPLETE busy=",busy," moves=",game.history.size()," rook_g2=",game.board[14]=="R")
	get_tree().quit()

func _qa_intro_sequence() -> void:
	_start_intro()
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png("user://intro-vanguard.png")
	await get_tree().create_timer(2.1).timeout
	get_viewport().get_texture().get_image().save_png("user://intro-royals.png")
	await get_tree().create_timer(5.0).timeout
	get_viewport().get_texture().get_image().save_png("user://intro-complete.png")
	print("QA_INTRO_COMPLETE active=",intro_active," moves=",game.history.size()," camera=",camera.position.is_equal_approx(board_camera))
	get_tree().quit()

func _qa_pyada_sequence() -> void:
	await get_tree().create_timer(.5).timeout
	_pyada_study()
	await get_tree().create_timer(.3).timeout
	get_viewport().get_texture().get_image().save_png("user://pyada-study.png")
	_make_move(11,20)
	for i in range(10):
		await get_tree().create_timer(.23).timeout
		get_viewport().get_texture().get_image().save_png("user://pyada-attack-%02d.png" % i)
	for i in range(100):
		if not busy: break
		await get_tree().create_timer(.1).timeout
	get_viewport().get_texture().get_image().save_png("user://pyada-capture-complete.png")
	print("QA_PYADA_CAPTURE_COMPLETE busy=",busy," pawn_e3=",game.board[20]=="P")
	_pyada_study()
	_make_move(11,19)
	for i in range(6):
		await get_tree().create_timer(.25).timeout
		get_viewport().get_texture().get_image().save_png("user://pyada-walk-%02d.png" % i)
	for i in range(60):
		if not busy: break
		await get_tree().create_timer(.1).timeout
	print("QA_PYADA_WALK_COMPLETE busy=",busy," pawn_d3=",game.board[19]=="P")
	get_tree().quit()

func _qa_portrait_sequence() -> void:
	await get_tree().create_timer(.5).timeout
	_pyada_portrait()
	await get_tree().create_timer(.5).timeout
	get_viewport().get_texture().get_image().save_png("user://pyada-portrait-front.png")
	pieces[11].rotation.y=.55
	await get_tree().create_timer(.4).timeout
	get_viewport().get_texture().get_image().save_png("user://pyada-portrait-profile.png")
	pieces[11].rotation.y=-.65
	await get_tree().create_timer(.4).timeout
	get_viewport().get_texture().get_image().save_png("user://pyada-portrait-other.png")
	print("QA_PORTRAIT_COMPLETE pieces=",pieces.size()," moves=",game.history.size())
	get_tree().quit()

func _qa_mount_sequence() -> void:
	await get_tree().create_timer(.5).timeout
	_mounted_study()
	await get_tree().create_timer(.5).timeout
	get_viewport().get_texture().get_image().save_png("user://royal-mounts-12.png")
	for square in [9,11,13]:
		var focus=_square_pos(square)+Vector3(0,.90,0)
		camera.position=focus+Vector3(1.7,.5,2.3); camera.look_at(focus); _update_court_visibility()
		await get_tree().create_timer(.4).timeout
		get_viewport().get_texture().get_image().save_png("user://mount-%s-12.png" % square)
	for move in [Vector2i(11,28),Vector2i(13,34)]:
		_mounted_study(); _make_move(move.x,move.y)
		await get_tree().create_timer(.8).timeout
		get_viewport().get_texture().get_image().save_png("user://mount-walk-%s-12.png" % move.x)
		for i in range(100):
			if not busy: break
			await get_tree().create_timer(.1).timeout
		print("QA_MOUNT_MOVE ",move," busy=",busy," destination=",game.board[move.y])
	print("QA_MOUNTS_COMPLETE")
	get_tree().quit()

func _qa_refined_mounts_sequence() -> void:
	await get_tree().create_timer(.5).timeout
	for role in ["n","b","p","q","k"]:
		for black in [false,true]:
			_mount_portrait(role,black)
			await get_tree().create_timer(.3).timeout; await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://mount-%s-%s-19.png" % [role,str(black)])
		_mount_portrait(role)
		var focus: Vector3=pieces[11].to_global(Vector3(0,1.08 if role=="b" else 1.00,.38))
		camera.position=focus+Vector3(.80,.19,1.25); camera.look_at(focus); _update_court_visibility()
		await get_tree().create_timer(.2).timeout; await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://mount-%s-face-19.png" % role)
	print("QA_REFINED_MOUNTS_COMPLETE")
	for role in ["q","k"]:
		_mount_portrait(role)
		var player=_animation_player(pieces[11])
		for clip in ["idle","walk","attack","threat","defeat","victory"]:
			_animate(pieces[11],clip)
			player.advance(.15)
			player.seek(player.current_animation_length*.45,true)
			player.pause()
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://royal-%s-%s-19.png" % [role,clip])
			print("QA_ROYAL_CLIP ",role," ",clip," duration=",player.current_animation_length)
	print("QA_ROYAL_CLIPS_COMPLETE")
	await _qa_encounters_sequence()

func _qa_royal_arms_sequence() -> void:
	await get_tree().create_timer(.5).timeout
	for role in ["q","k"]:
		_mount_portrait(role)
		var player=_animation_player(pieces[11])
		for phase in [.0,.25,.46,.50,.56,.72,1.0]:
			_animate(pieces[11],"attack")
			player.advance(.15)
			player.seek(player.current_animation_length*phase,true); player.pause()
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://arms-%s-%s-19.png" % [role,str(phase)])
			print("QA_ROYAL_ARM_POSE ",role," phase=",phase)
		_new_game(true)
		game=Rules.new("7k/8/8/8/3p4/8/3Q4/K7 w - - 0 1" if role=="q" else "7k/8/8/8/8/3p4/3K4/8 w - - 0 1")
		_sync_pieces(); _update_ui(); cinematic=true
		_make_move(11,27 if role=="q" else 19)
		await get_tree().create_timer(1.55).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://royal-capture-%s-19.png" % role)
		for i in range(100):
			if not busy: break
			await get_tree().create_timer(.1).timeout
		print("QA_ROYAL_CAPTURE_COMPLETE ",role," busy=",busy," pieces=",pieces.size()," moves=",game.history.size())
	print("QA_ROYAL_ARMS_COMPLETE")
	get_tree().quit()

func _qa_encounters_sequence() -> void:
	await get_tree().create_timer(.5).timeout
	for role in ["n","b"]:
		_encounter_study(role)
		var a=11 if role=="n" else 13
		var b=28 if role=="n" else 34
		var attacker: Node3D=pieces[a]; var victim: Node3D=pieces[b]
		var direction=(victim.position-attacker.position).normalized()
		attacker.position=MountedMotion.staging(attacker,victim,direction)
		attacker.rotation.y=atan2(direction.x,direction.z)
		var facing=attacker.position-victim.position
		victim.rotation.y=atan2(facing.x,facing.z)
		var focus=(attacker.position+victim.position)*.5+Vector3(0,.95,0)
		camera.position=MountedMotion.encounter_camera(focus,direction)
		camera.look_at(focus); _update_court_visibility(); _clear_markers()
		var state=MountedMotion.capture_state(attacker,victim,direction)
		for t in [.25,.44,.70,1.0]:
			MountedMotion.capture_frame(t,attacker,victim,state)
			await get_tree().create_timer(.12).timeout
			print("QA_RENDER_POSE ",role," t=",t," tip=",MountedMotion.blade_tip(state.rig,state.tip_local)," target=",state.target)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://encounter-%s-%s-15.png" % [role,str(t)])
		print("QA_BLADE_CONTACT ",role," error=",state.contact_error)
		assert(state.contact_error<.025)
		_encounter_study(role); _make_move(a,b)
		var recorded=false
		for i in range(240):
			if not busy: break
			if not recorded and pieces[a].get_meta("capture_phase","")=="contact":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("user://encounter-%s-live-15.png" % role)
				recorded=true
			await get_tree().create_timer(.025).timeout
		assert(not busy and pieces.size()==3 and game.history.size()==1)
		assert(camera.position.is_equal_approx(board_camera))
		print("QA_ENCOUNTER_COMPLETE ",role," pieces=",pieces.size()," moves=",game.history.size())
		await get_tree().create_timer(.1).timeout
		get_viewport().get_texture().get_image().save_png("user://encounter-%s-board-15.png" % role)
	print("QA_ENCOUNTERS_COMPLETE")
	get_tree().quit()

func _qa_armour_sequence() -> void:
	await get_tree().create_timer(.5).timeout
	_armour_study()
	await get_tree().create_timer(.5).timeout
	get_viewport().get_texture().get_image().save_png("user://armour-teams-12.png")
	for square in [25,27,29]:
		var focus=_square_pos(square)+Vector3(0,.95,0)
		camera.position=focus+Vector3(1.6,.5,2.6); camera.look_at(focus); _update_court_visibility()
		await get_tree().create_timer(.4).timeout
		get_viewport().get_texture().get_image().save_png("user://emerald-%s-12.png" % square)
	print("QA_ARMOUR_COMPLETE pieces=",pieces.size()," moves=",game.history.size())
	get_tree().quit()

func _qa_haathi_head_sequence() -> void:
	await get_tree().create_timer(.5).timeout
	_haathi_portrait()
	await get_tree().create_timer(.5).timeout
	get_viewport().get_texture().get_image().save_png("user://haathi-portrait-14.png")
	var focus=_square_pos(11)+Vector3(0,1.12,0)
	for angle in [0.0,1.15]:
		pieces[11].rotation.y=angle
		camera.position=focus+Vector3(.1,.12,1.65); camera.look_at(focus); _update_court_visibility()
		await get_tree().create_timer(.4).timeout
		get_viewport().get_texture().get_image().save_png("user://haathi-head-%s-14.png" % str(angle))
	_haathi_face()
	await get_tree().create_timer(.4).timeout
	get_viewport().get_texture().get_image().save_png("user://haathi-face-14.png")
	_haathi_portrait()
	_make_move(11,27)
	for i in range(100):
		if not busy: break
		await get_tree().create_timer(.1).timeout
	assert(not busy and game.board[27]=="R")
	print("QA_HAATHI_HEAD_COMPLETE pieces=",pieces.size()," moves=",game.history.size())
	get_tree().quit()

func _qa_haathi_body_sequence() -> void:
	await get_tree().create_timer(.5).timeout
	_haathi_portrait()
	await get_tree().create_timer(.5).timeout
	get_viewport().get_texture().get_image().save_png("user://haathi-body-14.png")
	var focus=_square_pos(11)+Vector3(0,.97,0)
	for angle in [1.3,2.8]:
		pieces[11].rotation.y=angle
		camera.position=focus+Vector3(.1,.28,2.95); camera.look_at(focus); _update_court_visibility()
		await get_tree().create_timer(.4).timeout
		get_viewport().get_texture().get_image().save_png("user://haathi-body-%s-14.png" % str(angle))
	_walk_study()
	for i in range(6):
		await get_tree().create_timer(.50).timeout
		get_viewport().get_texture().get_image().save_png("user://haathi-walk-%s-14.png" % str(i))
	for i in range(100):
		if not busy: break
		await get_tree().create_timer(.1).timeout
	assert(not busy and game.board[14]=="R")
	print("QA_HAATHI_BODY_COMPLETE pieces=",pieces.size()," moves=",game.history.size())
	get_tree().quit()

func _knight_study() -> void:
	_new_game(false)
	_end_intro()
	_make_move(1,18)


func _start_computer(level:int,side:String) -> void:
	computer.cancel();computer.enabled=true;computer.level=level;computer.human_side=side
	flipped=side=="b"
	_new_game();_home_play()

func _start_local() -> void:
	computer.cancel();computer.enabled=false
	_new_game();_home_play()
