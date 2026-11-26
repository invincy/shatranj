extends CanvasLayer
var app
var content: VBoxContainer
var scroll: ScrollContainer
var titles:Array[Label]=[]
var screen:="home"
var hero:Control
var hero_title:Label
var hero_subtitle:Label
var hero_controls:VBoxContainer
var veil:TextureRect
var drift:=0.0
var reduced_motion:=false
var settings:Button
var action_buttons:Array[Button]=[]
func _ready():
 layer=12
 if OS.has_feature("web"):reduced_motion=bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches"))
 var root:=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(root)
 veil=TextureRect.new();veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(veil)
 var gradient:=Gradient.new();gradient.set_color(0,Color(.02,.04,.045,.97));gradient.set_color(1,Color(.02,.04,.045,0));gradient.add_point(.42,Color(.02,.04,.045,.75))
 var texture:=GradientTexture2D.new();texture.gradient=gradient;texture.fill_from=Vector2.ZERO;texture.fill_to=Vector2(1,0);veil.texture=texture
 scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;root.add_child(scroll)
 content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",18);scroll.add_child(content)
 settings=app._button("",app._home_settings);settings.icon=load("res://assets/ui/settings.svg");settings.tooltip_text="Settings";settings.custom_minimum_size=Vector2(44,44);settings.add_theme_constant_override("icon_max_width",20)
 for state in ["normal","hover","pressed"]:
  var style=settings.get_theme_stylebox(state).duplicate();style.content_margin_left=6;style.content_margin_right=6;style.content_margin_top=6;style.content_margin_bottom=6;settings.add_theme_stylebox_override(state,style)
 root.add_child(settings)
 get_viewport().size_changed.connect(layout);layout();show_home()
func layout():
 if is_instance_valid(hero):layout_hero()
 var size:=get_viewport().get_visible_rect().size
 var narrow:=size.x<600
 for action_button in action_buttons:
  if is_instance_valid(action_button) and screen!="home":action_button.custom_minimum_size.y=(76 if size.x<380 else 72) if screen=="home" else (110 if size.x<380 else 88)
 if is_instance_valid(settings):settings.position=Vector2(size.x-56,10)
 scroll.position=Vector2(24 if narrow else size.x*.055, size.y*.12 if narrow and screen=="home" else (size.y*.07 if narrow else size.y*.065))
 scroll.size=Vector2(size.x-48 if narrow else minf(490,size.x*.60),size.y*.88)
 content.add_theme_constant_override("separation",10 if size.y<700 else 14)
 for title in titles:
  if is_instance_valid(title):title.add_theme_font_size_override("font_size",38 if narrow and screen=="home" else (30 if narrow else 40))
func clear():
 titles.clear();action_buttons.clear();scroll.scroll_vertical=0
 if is_instance_valid(hero):hero.hide()
 scroll.show();veil.show()
 for child in content.get_children():content.remove_child(child);child.queue_free()
func text(value:String,size:int=18):
 var label=preload("res://scripts/bilingual_labels.gd").label(value,size) if value.contains(" (") else app._label(value,size,app.LIGHT);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 if size>=32:
  titles.append(label)
  var font:=SystemFont.new();font.font_names=PackedStringArray(["Georgia","Noto Serif"]);label.add_theme_font_override("font",font);label.add_theme_color_override("font_color",app.GOLD)
 content.add_child(label);layout()
func button(label:String,callback:Callable,icon_name:String=""):
 if icon_name=="":
  icon_name="back" if label=="Back" else ("tactics" if label.begins_with("Pins") else ("opening" if label.begins_with("Openings") else "basics"))
 var b=app._button(label,callback);b.alignment=HORIZONTAL_ALIGNMENT_LEFT;b.custom_minimum_size.y=54;b.add_theme_font_size_override("font_size",17)
 b.icon=load("res://assets/ui/"+icon_name+".svg");b.add_theme_constant_override("h_separation",20);b.add_theme_constant_override("icon_max_width",30)
 b.add_theme_stylebox_override("normal",StyleBoxEmpty.new());b.add_theme_color_override("font_color",app.LIGHT);b.add_theme_color_override("font_hover_color",app.GOLD);content.add_child(b)
func show_home():
 screen="home";clear();scroll.hide();veil.hide()
 if is_instance_valid(hero):hero.queue_free()
 hero=Control.new();hero.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);get_child(0).add_child(hero);hero.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var shade=TextureRect.new();shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;hero.add_child(shade)
 var g=Gradient.new();g.set_color(0,Color(.015,.02,.018,.8));g.set_color(1,Color(.01,.018,.016,.96));g.add_point(.25,Color(.01,.02,.018,.02));g.add_point(.67,Color(.01,.02,.018,0));g.add_point(.82,Color(.01,.02,.018,.6))
 var tex=GradientTexture2D.new();tex.gradient=g;tex.fill_from=Vector2(.5,0);tex.fill_to=Vector2(.5,1);shade.texture=tex
 hero_title=app._label("SHATRANJ",48,Color("f4d78c"));hero_title.add_theme_font_override("font",preload("res://assets/fonts/Cinzel.ttf"));hero_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 hero_title.add_theme_color_override("font_shadow_color",Color("21190c"));hero_title.add_theme_constant_override("shadow_offset_y",3);hero_title.add_theme_constant_override("outline_size",1);hero.add_child(hero_title)
 hero_subtitle=app._label("THE ROYAL BATTLEFIELD",15,Color("e3c991"));hero_subtitle.add_theme_font_override("font",preload("res://assets/fonts/Cinzel.ttf"));hero_subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hero.add_child(hero_subtitle)
 hero_controls=VBoxContainer.new();hero_controls.add_theme_constant_override("separation",12);hero.add_child(hero_controls)
 var learn=royal_button("LEARN CHESS",show_learn,"res://assets/icons/k.svg",true);hero_controls.add_child(learn)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);hero_controls.add_child(row)
 row.add_child(royal_button("PLAY",show_play,"res://assets/ui/swords.svg"))
 row.add_child(royal_button("CHALLENGES",show_challenges,"res://assets/icons/n.svg"))
 get_child(0).move_child(settings,-1)
 layout()
func royal_button(caption:String,callback:Callable,icon:String,primary:=false)->Button:
 var b=preload("res://scripts/royal_menu_button.gd").new();b.caption=caption;b.primary=primary;b.progress_count=app.academy.completed.size();b.emblem=load(icon);b.custom_minimum_size.y=94 if primary else 64;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.tooltip_text="Choose a lesson or continue learning" if primary else caption.capitalize();b.pressed.connect(callback);action_buttons.append(b);return b
func layout_hero():
 if not is_instance_valid(hero_title):return
 var size=get_viewport().get_visible_rect().size
 var landscape=size.x>size.y*1.2
 var width=minf(size.x-32,560)
 var title_y=40.0 if size.y<700 else size.y*.08
 hero_title.position=Vector2(16,title_y);hero_title.size=Vector2(size.x-32,64);hero_title.add_theme_font_size_override("font_size",clampi(int(size.x*.105),30,64))
 hero_subtitle.position=Vector2(16,title_y+65);hero_subtitle.size=Vector2(size.x-32,25);hero_subtitle.add_theme_font_size_override("font_size",12 if size.x<380 else 16)
 if landscape:
  width=minf(size.x*.48,520)
  hero_title.position=Vector2(20,38);hero_title.size.x=size.x*.48;hero_title.add_theme_font_size_override("font_size",40)
  hero_subtitle.position=Vector2(20,98);hero_subtitle.size.x=size.x*.48
 hero_controls.position=Vector2((size.x-width)*.5,size.y-194)
 if landscape:hero_controls.position.x=24
 hero_controls.size=Vector2(width,170)
func _process(delta:float):
 if not app.home_active or screen!="home" or not visible or reduced_motion:return
 drift+=delta
 var offset=Vector3(sin(drift*.12)*.65,sin(drift*.09)*.18,cos(drift*.12)*.25)
 app.camera.position=app.board_camera+offset
 app.camera.look_at(app.board_look+Vector3(0,.2,0))
func action(title:String,subtitle:String,callback:Callable,icon:String,primary:=false):
 var b=app._button("",callback);b.custom_minimum_size.y=110 if get_viewport().get_visible_rect().size.x<380 else 88;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 b.add_theme_stylebox_override("normal",app._style(Color("23483ee8") if primary else Color("102326a0"),app.GOLD if primary else Color("4a5b50"),8))
 var row=HBoxContainer.new();row.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);row.offset_left=16;row.offset_right=-12;row.offset_top=10;row.offset_bottom=-10;b.add_child(row);row.add_theme_constant_override("separation",14)
 var image=TextureRect.new();image.texture=load("res://assets/icons/"+icon.trim_prefix("piece:")+".svg" if icon.begins_with("piece:") else "res://assets/ui/"+icon+".svg");image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.custom_minimum_size=Vector2(28,28);image.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(image)
 var words=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(words)
 for item in [[title,21],[subtitle,13]]:
  var label:Control
  if item[1]==21:
   label=preload("res://scripts/bilingual_labels.gd").label(item[0],21)
  else:
   label=app._label(item[0],item[1],app.LIGHT);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  label.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.add_child(label)
 content.add_child(b);action_buttons.append(b);layout();return b
func continue_learning():
 var index:int=app.academy.next_lesson()
 app._begin_training("basics" if index<7 else "tactics",index)
func confirm_new():
 var dialog:=ConfirmationDialog.new();dialog.dialog_text="Start a new match? Your current match will be replaced.";dialog.confirmed.connect(func():app._new_game();app._home_play());dialog.canceled.connect(dialog.queue_free);dialog.confirmed.connect(dialog.queue_free);add_child(dialog);dialog.popup_centered()
func show_learn():
 screen="learn";clear();text("Royal Academy",38);text("Continue your journey, or choose any lesson.",17)
 var next:int=app.academy.next_lesson()
 var lessons=preload("res://scripts/chess_lessons.gd").LESSONS
 if app.academy.completed.size()<9:
  action("Continue Learning" if not app.academy.completed.is_empty() else "Start Learning",lessons[next].title.split(" · ")[1],continue_learning,"learn",true)
 text("Your lessons · "+str(app.academy.completed.size())+"/9 completed",20)
 var subtitles=["Forward moves and diagonal captures","Straight lines and captures","Diagonals and captures","L-shaped jumps","Straight and diagonal moves","Safe squares and check","Move king and rook together","Why a pinned piece cannot move aside","Attack two targets at once"]
 for index in range(9):
  if index==0:text("Pieces and movement",18)
  elif index==6:text("Special moves",18)
  elif index==7:text("Tactics",18)
  var role=["p","r","b","n","q","k","k","r","n"][index]
  var lesson_button=action(lessons[index].title.split(" · ")[1],("Completed · " if app.academy.completed.has(index) else "Learn · ")+subtitles[index],open_lesson.bind(index),"piece:"+role)
  lesson_button.set_meta("lesson_index",index)
 text("Openings, strategy and endgames — coming later",15)
 button("Back",show_home)
func open_lesson(index:int):
 app._begin_training("basics" if index<7 else "tactics",index)
func stage(title:String,subtitle:String,indices:Array,first:int):
 var done:int=app.academy.count(indices)
 var next:=first
 for index in indices:
  if not app.academy.completed.has(index):next=index;break
 action(title,subtitle+" · "+str(done)+"/"+str(indices.size()),func():app._begin_training("basics" if next<7 else "tactics",next),"learn" if first==0 else "tactics")
func show_challenges():
 screen="challenges";clear();text("Tactical challenges",38);text("Keep your king safe. Find the double attack.",17)
 action("Break the pin","Free your Haathi without exposing your Raja",func():app._begin_training("tactics",7),"tactics")
 action("Find the fork","Attack two targets with your Ghoda",func():app._begin_training("tactics",8),"tactics")
 text("Guided challenges · more positions coming later",13);button("Back",show_home)
func show_progress():
 screen="progress";clear();text("Your academy record",38)
 text(str(app.academy.xp())+" XP · "+str(app.academy.completed.size())+" of 9 exercises",22)
 var meter=ProgressBar.new();meter.max_value=9;meter.value=app.academy.completed.size();meter.show_percentage=false;meter.custom_minimum_size.y=8;content.add_child(meter)
 for row in [["Recruit (पदाति) · movement",[0,1,2,3,4,5]],["Cavalry (अश्वारोही) · castling",[6]],["Warrior (योद्धा) · tactics",[7,8]]]:
  var count:int=app.academy.count(row[1]);text(row[0]+"  "+str(count)+"/"+str(row[1].size()),18)
 text("Achievements",22)
 for item in [["First command",app.academy.completed.size()>0],["Know your army",app.academy.count([0,1,2,3,4,5])==6],["Tactical eye",app.academy.count([7,8])==2]]:
  text(("Earned · " if item[1] else "Not yet · ")+item[0],15)
 text("Saved on this device/browser. Replaying a lesson does not duplicate XP. Clearing app data removes this record.",12)
 action("Review lessons" if app.academy.completed.size()==9 else "Continue Learning","Return to your training ground",continue_learning,"learn",true)
 button("Back",show_home)
func show_openings():show_learn()
func open_lessons(_category:String):show_learn()


func show_play():
 screen="play";clear();text("Enter the battlefield",38)
 action("Play Computer","Choose your army and difficulty",show_computer,"play",true)
 action("Local two-player","Share this screen with a friend",func():confirm_start(app._start_local),"basics")
 if not app.game.history.is_empty():button("Continue battle",app._home_play,"play")
 button("Back",show_home)
func confirm_start(start:Callable):
 if app.game.history.is_empty():start.call();return
 var dialog:=ConfirmationDialog.new();dialog.dialog_text="Start a new battle? This replaces your current match."
 dialog.confirmed.connect(start);dialog.confirmed.connect(dialog.queue_free);dialog.canceled.connect(dialog.queue_free);add_child(dialog);dialog.popup_centered()
func show_computer():
 screen="computer";clear();text("Play Computer",38);text("Command your army against Stockfish.",17)
 if not OS.has_feature("web"):
  text("Available on our browser app for phones and computers.",16)
  button("Open browser game",func():OS.shell_open("https://invincy.github.io/shatranj/"),"play");button("Back",show_play);return
 text("Difficulty",18)
 var difficulty:=OptionButton.new();difficulty.custom_minimum_size.y=48;difficulty.add_theme_font_size_override("font_size",20)
 for n in range(1,11):difficulty.add_item("Level "+str(n)+(" · Gentle" if n==1 else (" · Strongest" if n==10 else "")))
 difficulty.select(app.computer.level-1);content.add_child(difficulty)
 text("Your army",18)
 var side:=OptionButton.new();side.custom_minimum_size.y=48;side.add_theme_font_size_override("font_size",18)
 side.add_item("Saffron · White · moves first");side.add_item("Emerald · Black · moves second");content.add_child(side)
 side.select(0 if app.computer.human_side=="w" else 1)
 text("Levels 1–10 adjust strength and thinking time. These are not Elo ratings. Undo returns to your turn.",14)
 action("Begin battle","Your pieces, the same cinematic battlefield",func():confirm_start(func():app._start_computer(difficulty.selected+1,"w" if side.selected==0 else "b")),"play",true)
 button("Stockfish credits",func():OS.shell_open("https://invincy.github.io/shatranj/stockfish/credits.html"),"settings")
 button("Back",show_play)
