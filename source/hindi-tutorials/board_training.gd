extends CanvasLayer
const Lessons=preload("res://scripts/chess_lessons.gd")
const LessonVoice=preload("res://scripts/lesson_voice.gd")
var voice
var voice_status:Label
var voice_mute:CheckButton
var app
var panel:PanelContainer
var category:="basics"
var available:Array=[]
var index:=0
var complete:=false
var selected:=false
var saved:Dictionary={}
var feedback:Label
var heading:Label
var picker:OptionButton
var next_button:Button
var progress:Label
var completed:Dictionary={}
func _ready():
 layer=13
 for key in ["game","notation","last_move","facing_by_square","cinematic","flipped","board_look","view_yaw","view_tilt","view_distance"]:saved[key]=app.get(key)
 var empty_notation:Array[String]=[]
 app.notation=empty_notation;app.last_move={};app.facing_by_square={};app.cinematic=false;app.flipped=false
 available=[0,1,2,3,4,5,6] if category=="basics" else [7,8]
 panel=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.anchor_left=.72;panel.offset_left=10;panel.offset_right=-12;panel.offset_top=24;panel.offset_bottom=-24;add_child(panel)
 panel.add_theme_stylebox_override("panel",app._style(Color("102326"),Color("8c734a"),4))
 var outer:=VBoxContainer.new();outer.add_theme_constant_override("separation",8);panel.add_child(outer)
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;outer.add_child(scroll)
 var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",18);scroll.add_child(box)
 box.add_child(app._label("TRAINING GROUND",18,app.GOLD))
 picker=OptionButton.new();picker.custom_minimum_size.y=44;picker.clip_text=true
 for i in available:picker.add_item(Lessons.LESSONS[i].title,i)
 picker.item_selected.connect(func(item):load_lesson(picker.get_item_id(item)));box.add_child(picker)
 heading=label("",23);box.add_child(heading)
 feedback=label("",18);box.add_child(feedback)
 progress=label("",15);box.add_child(progress)
 voice=LessonVoice.new();voice.sound=app.sound;add_child(voice)
 voice_status=label("Hindi narration",15);box.add_child(voice_status)
 var audio_controls:=HBoxContainer.new();outer.add_child(audio_controls)
 var replay=app._button("Listen again",play_narration);replay.size_flags_horizontal=Control.SIZE_EXPAND_FILL;audio_controls.add_child(replay)
 voice_mute=CheckButton.new();voice_mute.text="Mute voice";voice_mute.custom_minimum_size.y=44;voice_mute.button_pressed=LessonVoice.muted;audio_controls.add_child(voice_mute)
 voice_mute.toggled.connect(func(value):voice.set_muted(value);voice_status.text="Voice muted" if value else "Hindi narration — tap Listen again")
 var actions:=HBoxContainer.new();outer.add_child(actions)
 var retry=app._button("Try again",func():load_lesson(index));retry.size_flags_horizontal=Control.SIZE_EXPAND_FILL;actions.add_child(retry)
 next_button=app._button("Next lesson",func():load_lesson(available[(available.find(index)+1)%available.size()]));next_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;actions.add_child(next_button)
 var navigation:=HBoxContainer.new();outer.add_child(navigation)
 var leave_button=app._button("Back",app._show_home);leave_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;navigation.add_child(leave_button)
 for amount in [1.5,-1.5]:
  var zoom=app._button("−" if amount>0 else "+",func():app.mobile_layout.zoom(amount));zoom.custom_minimum_size=Vector2(48,48);navigation.add_child(zoom)
 layout();load_lesson(available[0])
func layout():
 if not panel:return
 var size:=get_viewport().get_visible_rect().size
 var portrait:=size.y>size.x
 app.camera.keep_aspect=Camera3D.KEEP_WIDTH if portrait else Camera3D.KEEP_HEIGHT
 if heading:heading.visible=size.x>=1000 and size.y>=600
 if portrait:
  app.mobile_layout.rect(app.board_container,Vector2(0,0),Vector2(size.x,size.y*.55))
  app.mobile_layout.rect(panel,Vector2(10,size.y*.55+6),Vector2(size.x-20,size.y*.45-16))
 else:
  app.mobile_layout.rect(app.board_container,Vector2.ZERO,Vector2(size.x*.66 if size.y<600 else size.x*.72,size.y))
  var left:float=app.board_container.size.x+8
  app.mobile_layout.rect(panel,Vector2(left,10),Vector2(size.x-left-10,size.y-20))
func label(value:String,size:int)->Label:
 var result=app._label(value,size,app.LIGHT);result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return result
func load_lesson(value:int):
 if app.busy:picker.select(available.find(index));return
 index=value;complete=false;selected=false;picker.select(available.find(index));next_button.disabled=true
 var lesson:Dictionary=Lessons.LESSONS[index]
 app.game=app.Rules.new(lesson.fen);app.notation.clear();app.last_move={};app.facing_by_square={};app.selected=-1;app._clear_markers();app._sync_pieces();app._update_ui();app.ended=false
 app.board_look=Vector3(0,.65,0);app._set_view(0,48,15)
 app._marker(lesson.from,app.GOLD,false)
 heading.text=lesson.title.split(" · ")[1]
 feedback.text=lesson.text.split(". ")[0]+".\nTap the gold-marked "+app.NAMES[str(app.game.board[lesson.from]).to_lower()]+" on "+app.Rules.square_name(lesson.from)+"."
 progress.text=str(completed.size())+" / "+str(available.size())+" completed"
 play_narration()
func play_narration():
 if LessonVoice.muted or app.sound.muted:
  voice.stop();voice_status.text="Voice muted";return
 voice_status.text="Hindi narration" if voice.play_lesson(index) else "Audio unavailable — follow the written lesson"
func tap(square:int):
 if app.busy or complete:return
 var lesson:Dictionary=Lessons.LESSONS[index]
 if square==lesson.from:
  selected=true;app._select(square);feedback.text=lesson.task+"\nGreen: move · Coral: capture";return
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
 if app.game.history.is_empty():return
 complete=true;selected=false;completed[index]=true;next_button.disabled=false
 feedback.text="Well done!\n\n"+("Both the Raja and Haathi moved together." if index==6 else ("Your Ghoda now attacks the king on c7 and the rook on f6." if index==8 else ("You removed the pinning rook and kept your Raja safe." if index==7 else "You made a legal move on the battlefield.")))
 progress.text=str(completed.size())+" / "+str(available.size())+" completed"
 if index==8:
  app._marker(50,app.GOLD,false);app._marker(45,app.GOLD,false)
func leave():
 voice.stop()
 if app.busy:app._skip()
 app.training=null
 for key in saved:app.set(key,saved[key])
 app.selected=-1;app._clear_markers();app._sync_pieces();app._update_ui();app._set_view(app.view_yaw,app.view_tilt,app.view_distance)
 queue_free()
