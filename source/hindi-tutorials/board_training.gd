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
var heading:Label
var picker:OptionButton
var next_button:Button
var progress:Label
var completed:Dictionary={}
var phase:="demo"
var lesson_serial:=0
# Clip-local instruction onsets from V2 measured transcription; pin uses an approximate onset because that passage lacks reliable word alignment.
const PRACTICE_CUES=[12.12,12.68,15.60,14.19,12.02,12.99,21.26,17.0,10.17]
const DEMO_TARGETS=[28,51,54,44,30,26,6,60,35]
var lesson_elapsed:=0.0
var guidance:Control
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
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;outer.add_child(scroll)
 var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",8);scroll.add_child(box)
 picker=OptionButton.new();picker.custom_minimum_size.y=44;picker.clip_text=true
 for i in available:picker.add_item(Lessons.LESSONS[i].title,i)
 picker.item_selected.connect(func(item):load_lesson(picker.get_item_id(item)));box.add_child(picker)
 heading=label("",23);box.add_child(heading)
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
 next_button=app._button("Next lesson →",advance);outer.add_child(next_button)
 guidance=preload("res://scripts/tutorial_guidance.gd").new();guidance.training=self;add_child(guidance)
 layout();load_lesson(start_index if start_index in available else available[0])
func layout():
 if not panel:return
 var size:=get_viewport().get_visible_rect().size
 var portrait:=size.y>size.x
 app.camera.keep_aspect=Camera3D.KEEP_WIDTH if portrait else Camera3D.KEEP_HEIGHT
 if heading:heading.visible=size.x>=1000 and size.y>=600
 if portrait:
  app.mobile_layout.rect(app.board_container,Vector2(0,0),Vector2(size.x,size.y*.64))
  app.mobile_layout.rect(panel,Vector2(10,size.y*.64+6),Vector2(size.x-20,size.y*.36-16))
 else:
  app.mobile_layout.rect(app.board_container,Vector2.ZERO,Vector2(size.x*.66 if size.y<600 else size.x*.72,size.y))
  var left:float=app.board_container.size.x+8
  app.mobile_layout.rect(panel,Vector2(left,10),Vector2(size.x-left-10,size.y-20))
func label(value:String,size:int)->Label:
 var result=app._label(value,size,app.LIGHT);result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return result
func load_lesson(value:int):
 if app.busy:picker.select(available.find(index));return
 lesson_serial+=1;phase="demo";lesson_elapsed=0.0
 index=value;complete=false;selected=false;picker.select(available.find(index));next_button.disabled=true;next_button.visible=false
 var lesson:Dictionary=Lessons.LESSONS[index]
 app.game=app.Rules.new(lesson.fen);app.notation.clear();app.last_move={};app.facing_by_square={};app.selected=-1;app._clear_markers();app._sync_pieces();app._update_ui();app.ended=false
 app.board_look=Vector3(0,.65,0);app._set_view(0,48,15)
 app._marker(lesson.from,app.GOLD,false)
 heading.text=lesson.title.split(" · ")[1]
 feedback.text="Watch first\n"+lesson.text.split(". ")[0]+"."
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
 next_button.text="Finish lessons ✓" if index==available.back() else "Next lesson →"
 feedback.text="Well done!\n\n"+("Both the Raja and Haathi moved together." if index==6 else ("Your Ghoda now attacks the king on c7 and the rook on f6." if index==8 else ("You removed the pinning rook and kept your Raja safe." if index==7 else "You made a legal move on the battlefield.")))
 progress.text=str(app.academy.count(available))+" / "+str(available.size())+" completed"
 if app.academy.save_failed:progress.text+=" · Could not save on this device"
 if index==8:
  app._marker(50,app.GOLD,false);app._marker(45,app.GOLD,false)
func leave():
 phase="leaving";lesson_serial+=1
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
 await get_tree().create_timer(.8).timeout
 if serial!=lesson_serial or phase!="demo":return
 var lesson:Dictionary=Lessons.LESSONS[index]
 # Stable examples use the same coordinates as the supplied narration.
 var destinations=DEMO_TARGETS
 app._select(lesson.from)
 await get_tree().create_timer(.9).timeout
 if serial!=lesson_serial or phase!="demo":return
 feedback.text="Watch the highlighted move…"
 app._make_move(lesson.from,destinations[index])
func finish_demonstration(serial:int):
 phase="demo_reset"
 feedback.text="Watch and listen\n"+Lessons.LESSONS[index].text
 await get_tree().create_timer(1.1).timeout
 if serial!=lesson_serial or phase!="demo_reset":return
 var lesson:Dictionary=Lessons.LESSONS[index]
 app.game=app.Rules.new(lesson.fen);app.notation.clear();app.last_move={};app.facing_by_square={};app.selected=-1;app._clear_markers();app._sync_pieces();app._update_ui();app.ended=false
 selected=false;phase="waiting_cue"
 app._marker(lesson.from,app.GOLD,false)
 feedback.text="Watch and listen\n"+lesson.text.split(". ")[0]+"."

func _process(delta:float):
 lesson_elapsed+=delta
 if phase=="waiting_cue":
  var timeline=voice.player.get_playback_position() if voice.player.playing else lesson_elapsed
  if timeline>=PRACTICE_CUES[index]:
   phase="practice"
   feedback.text="Your turn — tap "+app.Rules.square_name(Lessons.LESSONS[index].from)+"\n"+Lessons.LESSONS[index].task
