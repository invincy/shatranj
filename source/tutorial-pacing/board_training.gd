extends CanvasLayer
const Lessons=preload("res://scripts/chess_lessons.gd")
const LessonVoice=preload("res://scripts/lesson_voice.gd")
var voice
var voice_status:Label
var voice_mute:Button
var app
var panel:PanelContainer
var category:="basics"
var available:Array=[]
var index:=0
var start_index:=-1
var complete:=false
var selected:=false
var saved:Dictionary={}
var feedback:Label
var heading:RichTextLabel
var picker_caption:RichTextLabel
const Labels=preload("res://scripts/bilingual_labels.gd")
var picker:OptionButton
var next_button:Button
var progress:Label
var completed:Dictionary={}
var phase:="demo"
var lesson_serial:=0
# Clip-local instruction onsets from V2 measured transcription; pin uses an approximate onset because that passage lacks reliable word alignment.
const PRACTICE_CUES=[12.12,12.68,15.60,14.19,12.02,12.99,21.26,17.0,10.17]
const DEMO_TARGETS=[19,51,54,44,30,26,6,60,35]
# Demonstration-only defenders. Practice always restores the narrated original FEN.
const DEMO_DEFENDERS={1:51,2:54,3:44,4:30,5:26}
const DEMO_CAPTIONS=["Pawn captures one square diagonally: e2 to d3.","Rook travels straight to d7 and captures on arrival.","Bishop follows the diagonal to g7 and captures there.","Knight jumps in an L, landing on e6 to capture.","Queen aims along a clear rank and captures on g4.","King captures on c4: one square, safely away from attack.","King moves two squares; the rook escorts it to f1.","Capture the pinning rook while keeping the king protected.","Knight lands on d5, attacking the king and rook together."]
var narration_held:=false
var top_bar:HBoxContainer
var tutorial_badges:Control
var motion_started:=0.0
var motion_elapsed:=0.0
var lesson_elapsed:=0.0
var guidance:Control
var portrait_view:SubViewportContainer
var camera_tween:Tween
var shot_active:=false
func _ready():
 layer=13
 completed=app.academy.completed.duplicate()
 for key in ["game","notation","last_move","facing_by_square","cinematic","flipped","board_look","view_yaw","view_tilt","view_distance"]:saved[key]=app.get(key)
 var empty_notation:Array[String]=[]
 app.notation=empty_notation;app.last_move={};app.facing_by_square={};app.cinematic=false;app.flipped=false
 available=[0,1,2,3,4,5,6] if category=="basics" else [7,8]
 panel=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.anchor_left=.72;panel.offset_left=10;panel.offset_right=-12;panel.offset_top=24;panel.offset_bottom=-24;add_child(panel)
 panel.add_theme_stylebox_override("panel",app._style(Color("102326"),Color("8c734a"),4))
 var outer:=VBoxContainer.new();outer.add_theme_constant_override("separation",8);panel.add_child(outer)
 var body:=HBoxContainer.new();body.add_theme_constant_override("separation",8);body.size_flags_vertical=Control.SIZE_EXPAND_FILL;outer.add_child(body)
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(scroll)
 portrait_view=preload("res://scripts/tutorial_portrait.gd").new();portrait_view.app=app;portrait_view.custom_minimum_size.x=120;body.add_child(portrait_view)
 var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",8);scroll.add_child(box)
 picker=OptionButton.new();picker.custom_minimum_size.y=44;picker.clip_text=true;picker.fit_to_longest_item=false;picker.clip_contents=true
 picker.add_theme_font_override("font",Labels.FONT);picker.get_popup().add_theme_font_override("font",Labels.FONT)
 for i in available:
  var role=["p","r","b","n","q","k","k","r","n"][i]
  picker.add_icon_item(load("res://assets/icons/"+role+".svg"),Lessons.LESSONS[i].title,i)
 picker.add_theme_constant_override("icon_max_width",22)
 picker.item_selected.connect(func(item):load_lesson(picker.get_item_id(item)));top_bar=HBoxContainer.new();top_bar.add_theme_constant_override("separation",8);add_child(top_bar)
 picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top_bar.add_child(picker)
 picker_caption=Labels.label("",18);picker_caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);picker_caption.offset_left=12;picker_caption.offset_right=-30;picker_caption.offset_top=7;picker.add_child(picker_caption)
 heading=Labels.label("",23);box.add_child(heading)
 feedback=label("",16);box.add_child(feedback)
 progress=label("",12);box.add_child(progress)
 voice=LessonVoice.new();voice.sound=app.sound;add_child(voice)
 voice_status=label("Hinglish narration",12);voice_status.modulate.a=.7;voice_status.visible=false;box.add_child(voice_status)
 var tools_row:=HBoxContainer.new();tools_row.add_theme_constant_override("separation",4);outer.add_child(tools_row)
 tools_row.add_child(icon_button("back", "Back to home", app._show_home))
 tools_row.add_child(icon_button("replay", "Replay guided lesson", func():load_lesson(index)))
 voice_mute=icon_button("sound", "Mute narration", func():pass);voice_mute.toggle_mode=true;voice_mute.button_pressed=LessonVoice.muted;tools_row.add_child(voice_mute)
 voice_mute.toggled.connect(func(value):voice.set_muted(value);voice_mute.icon=load("res://assets/ui/tutorial-"+("muted" if value else "sound")+".svg");voice_mute.tooltip_text="Unmute narration" if value else "Mute narration";voice_status.text="Voice muted" if value else "Hinglish narration")
 voice_mute.icon=load("res://assets/ui/tutorial-"+("muted" if LessonVoice.muted else "sound")+".svg")
 tools_row.add_child(icon_button("retry", "Watch demonstration again", func():load_lesson(index)))
 var more=MenuButton.new();more.text="⋯";more.tooltip_text="Board zoom";more.custom_minimum_size=Vector2(44,44);tools_row.add_child(more)
 more.get_popup().add_item("Zoom in",0);more.get_popup().add_item("Zoom out",1)
 more.get_popup().id_pressed.connect(func(id):app.mobile_layout.zoom(-1.5 if id==0 else 1.5))
 next_button=app._button("Next →",advance);next_button.tooltip_text="Next lesson";top_bar.add_child(next_button)
 tutorial_badges=preload("res://scripts/piece_badges.gd").new();tutorial_badges.game_view=app;tutorial_badges.tutorial=true;tutorial_badges.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(tutorial_badges)
 guidance=preload("res://scripts/tutorial_guidance.gd").new();guidance.training=self;add_child(guidance)
 layout();load_lesson(start_index if start_index in available else available[0])
func layout():
 if not panel:return
 var size:=get_viewport().get_visible_rect().size
 var portrait:=size.y>size.x
 if top_bar:app.mobile_layout.rect(top_bar,Vector2(10,10),Vector2(size.x-20,48))
 app.camera.keep_aspect=Camera3D.KEEP_WIDTH if portrait else Camera3D.KEEP_HEIGHT
 if heading:heading.visible=size.x>=1000 and size.y>=600
 if portrait:
  app.mobile_layout.rect(app.board_container,Vector2(0,66),Vector2(size.x,size.y*.60-66))
  app.mobile_layout.rect(panel,Vector2(10,size.y*.60+6),Vector2(size.x-20,size.y*.40-16))
 else:
  app.mobile_layout.rect(app.board_container,Vector2(0,66),Vector2(size.x*.66 if size.y<600 else size.x*.72,size.y-66))
  var left:float=app.board_container.size.x+8
  app.mobile_layout.rect(panel,Vector2(left,66),Vector2(size.x-left-10,size.y-76))
 if portrait_view:portrait_view.custom_minimum_size.x=clampf((panel.size.x-44)*.40,80,160)
 if tutorial_badges:app.mobile_layout.rect(tutorial_badges,app.board_container.position,app.board_container.size)
func label(value:String,size:int)->Label:
 var result=app._label(value,size,app.LIGHT);result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return result
func load_lesson(value:int):
 if app.busy:picker.select(available.find(index));return
 lesson_serial+=1;phase="demo";lesson_elapsed=0.0;narration_held=false;motion_elapsed=0.0
 stop_camera()
 index=value;complete=false;selected=false;picker.select(available.find(index));next_button.disabled=true;next_button.visible=false
 var lesson:Dictionary=Lessons.LESSONS[index]
 app.game=app.Rules.new(lesson.fen)
 if DEMO_DEFENDERS.has(index) and phase=="demo":app.game.board[DEMO_DEFENDERS[index]]="p"
 app.notation.clear();app.last_move={};app.facing_by_square={};app.selected=-1;app._clear_markers();app._sync_pieces();app._update_ui();app.ended=false
 app.board_look=Vector3(0,.65,0);app._set_view(0,48,15)
 app._marker(lesson.from,app.GOLD,false)
 var display:String=lesson.title.split(" · ")[1]
 var role=["p","r","b","n","q","k","k","r","n"][index]
 var title:String="[img=20x20]res://assets/icons/"+role+".svg[/img] "+Labels.format_name(display)
 heading.text=title;picker_caption.text=title;picker.text="";picker.icon=null
 portrait_view.show_piece(str(app.game.board[lesson.from]),lesson.from)
 feedback.text="Watch the demonstration\n\n"+DEMO_CAPTIONS[index]
 progress.text=str(app.academy.count(available))+" / "+str(available.size())+" completed"
 play_narration()
 demonstrate(lesson_serial)
func play_narration():
 if LessonVoice.muted or app.sound.muted:
  voice.stop();voice_status.text="Voice muted";return
 var playing:bool=voice.play_lesson(index)
 voice_status.visible=not playing
 voice_status.text="Hinglish narration" if playing else "Audio unavailable — follow the written lesson"
func tap(square:int):
 if phase!="practice" or app.busy or complete:return
 var lesson:Dictionary=Lessons.LESSONS[index]
 if square==lesson.from:
  selected=true;app._select(square);feedback.text="Now tap a highlighted destination.\nGreen: move · Coral: capture";return
 if not selected:
  feedback.text="First tap the gold-marked piece on "+app.Rules.square_name(lesson.from)+".";return
 var legal:=false
 for move in app.game.legal_moves(lesson.from):
  if move.to==square:legal=true
 if not legal:
  feedback.text="That square is not legal. "+("Moving sideways would expose your Raja to the rook." if index==7 else "Choose one of the highlighted squares.");return
 if not lesson.targets.is_empty() and square not in lesson.targets:
  feedback.text="That move is legal, but this challenge is: "+lesson.task;return
 feedback.text="Watch your piece move…";app._make_move(lesson.from,square)
func move_finished():
 if phase=="leaving":return
 if phase=="demo":
  finish_demonstration(lesson_serial);return
 if app.game.history.is_empty():return
 app.academy.finish(index)
 phase="complete";complete=true;selected=false;completed[index]=true;next_button.disabled=false;next_button.visible=true
 next_button.text="Finish ✓" if index==available.back() else "Next →"
 feedback.text="Well done!\n\n"+("Both the Raja and Haathi moved together." if index==6 else ("Your Ghoda now attacks the king on c7 and the rook on f6." if index==8 else ("You removed the pinning rook and kept your Raja safe." if index==7 else "You made a legal move on the battlefield.")))
 progress.text=str(app.academy.count(available))+" / "+str(available.size())+" completed"
 if app.academy.save_failed:progress.text+=" · Could not save on this device"
 if index==8:
  app._marker(50,app.GOLD,false);app._marker(45,app.GOLD,false)
func leave():
 phase="leaving";lesson_serial+=1
 stop_camera()
 voice.stop()
 if app.busy:app._skip()
 app.training=null
 for key in saved:app.set(key,saved[key])
 app.selected=-1;app._clear_markers();app._sync_pieces();app._update_ui();app._set_view(app.view_yaw,app.view_tilt,app.view_distance)
 queue_free()

func icon_button(symbol:String,tip:String,action:Callable)->Button:
 var button=Button.new();button.icon=load("res://assets/ui/tutorial-"+symbol+".svg");button.tooltip_text=tip;button.custom_minimum_size=Vector2(44,44);button.flat=true;button.pressed.connect(action);return button
func advance():
 if not complete:return
 if index==available.back():app._show_home()
 else:load_lesson(available[available.find(index)+1])
func demonstrate(serial:int):
 await get_tree().create_timer(1.0).timeout
 if serial!=lesson_serial or phase!="demo":return
 var lesson:Dictionary=Lessons.LESSONS[index]
 var start:Vector3=app._square_pos(lesson.from)
 var destination:Vector3=app._square_pos(DEMO_TARGETS[index])
 var focus:Vector3=start+Vector3(0,1.0,0)
 shot_active=true
 app._animate(app.pieces[lesson.from],"idle")
 await camera_shot(focus+Vector3(3.7,1.8,-3.5),focus,1.5)
 if serial!=lesson_serial or phase!="demo":return
 await get_tree().create_timer(1.0).timeout
 if serial!=lesson_serial or phase!="demo":return
 # Hold a three-quarter view that includes the route AND the defender.
 var middle=(start+destination)*.5+Vector3(0,.8,0)
 var distance=start.distance_to(destination)
 var direction=(destination-start).normalized()
 var profile=Vector3(-direction.z,0,direction.x)
 var offset=profile*(4.6+distance*.4)+direction*1.6+Vector3(0,3.4+distance*.32,0)
 if index==3 or index==8:offset.y+=1.2
 await camera_shot(middle+offset,middle,1.5)
 if serial!=lesson_serial or phase!="demo":return
 app.cinematic=true;motion_started=lesson_elapsed
 app._make_move(lesson.from,DEMO_TARGETS[index])
func stop_camera():
 if camera_tween and camera_tween.is_running():camera_tween.kill()
 shot_active=false
func camera_shot(position:Vector3,target:Vector3,duration:float):
 camera_tween=create_tween()
 camera_tween.tween_method(app._camera_blend.bind(app.camera.position,position,app.camera.quaternion,app._look_quat(position,target)),0.0,1.0,duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
 await camera_tween.finished
func finish_demonstration(serial:int):
 motion_elapsed=lesson_elapsed-motion_started
 phase="demo_reset"
 # Let the capture/arrival read before returning to the full board.
 await get_tree().create_timer(2.2).timeout
 if serial!=lesson_serial or phase!="demo_reset":return
 await camera_shot(app.board_camera,app.board_look,1.8)
 if serial!=lesson_serial or phase!="demo_reset":return
 shot_active=false;app.cinematic=false
 var lesson:Dictionary=Lessons.LESSONS[index]
 app.game=app.Rules.new(lesson.fen);app.notation.clear();app.last_move={};app.facing_by_square={};app.selected=-1;app._clear_markers();app._sync_pieces();app._update_ui();app.ended=false
 selected=false;phase="waiting_cue"
 # Keep the explanation stable until the learner is actually invited to act.
 await get_tree().create_timer(.8).timeout
 if serial!=lesson_serial or phase!="waiting_cue":return
 if narration_held:
  voice.player.stream_paused=false;narration_held=false

func _process(delta:float):
 lesson_elapsed+=delta
 if phase in ["demo","demo_reset"] and voice.player.playing and not narration_held:
  if voice.player.get_playback_position()>=PRACTICE_CUES[index]-.2:
   voice.player.stream_paused=true;narration_held=true
 if phase=="waiting_cue" and not narration_held:
  var timeline=voice.player.get_playback_position() if voice.player.playing else lesson_elapsed
  if timeline>=PRACTICE_CUES[index]:
   phase="practice"
   app._marker(Lessons.LESSONS[index].from,app.GOLD,false)
   feedback.text="Your turn — tap "+app.Rules.square_name(Lessons.LESSONS[index].from)+"\n\n"+Lessons.LESSONS[index].task
