extends Node
var app
var compact:=false
var drawer:=false
var bar:HBoxContainer
var status:Label
var controls:Button
var home_button:Button
func _ready():
 bar=HBoxContainer.new();bar.add_theme_constant_override("separation",6);app.game_ui.add_child(bar)
 for item in [["Home",app._show_home],["Controls",toggle],["Turn",app._flip],["−",zoom.bind(1.5)],["+",zoom.bind(-1.5)]]:
  var button=app._button(item[0],item[1]);button.custom_minimum_size=Vector2(48,52);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.add_theme_font_size_override("font_size",16);bar.add_child(button)
  for state in ["normal","hover","pressed"]:
   var style=button.get_theme_stylebox(state).duplicate();style.content_margin_left=8;style.content_margin_right=8;button.add_theme_stylebox_override(state,style)
  if item[0]=="Controls":controls=button
  if item[0]=="Home":home_button=button;home_button.icon=load("res://assets/ui/back.svg");home_button.tooltip_text="Home"
 status=app._label("",17,app.GOLD);status.mouse_filter=Control.MOUSE_FILTER_IGNORE;status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;app.game_ui.add_child(status)
 layout()
func toggle():drawer=not drawer;layout()
func zoom(amount:float):app._set_view(app.view_yaw,app.view_tilt,app.view_distance+amount)
func rect(control:Control,position:Vector2,size:Vector2):
 control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT);control.position=position;control.size=size
func refresh():
 if not status:return
 status.text=("Saffron" if app.game.turn=="w" else "Emerald")+" to move"+(" · CHECK" if app.game.in_check() else "")
 if app.game.outcome()!="":status.text=app.game.outcome().replace("_"," ").capitalize()
func layout():
 if not is_instance_valid(app.ui_side):return
 var size:Vector2=app.get_viewport().get_visible_rect().size
 compact=size.x<1000 or size.y<600 or OS.has_feature("android")
 var safe_top:=0.0;var safe_bottom:=0.0
 if OS.has_feature("android"):
  var safe:=DisplayServer.get_display_safe_area();var physical:=DisplayServer.screen_get_size()
  if physical.y>0 and safe.size.y>0:
   safe_top=maxf(0,safe.position.y)*size.y/physical.y
   safe_bottom=maxf(0,physical.y-safe.end.y)*size.y/physical.y
 var portrait:=size.y>size.x
 app.camera.keep_aspect=Camera3D.KEEP_WIDTH if portrait and not app.home_active else Camera3D.KEEP_HEIGHT
 bar.visible=compact and not app.intro_active;status.visible=compact and not app.intro_active
 app.ui_top.visible=not compact;app.ui_bottom.visible=not compact
 app.ui_side.visible=not compact or drawer
 if compact:
  rect(status,Vector2(16,14+safe_top),Vector2(size.x-32,40))
  controls.text="Close" if drawer else ("Menu" if size.x<380 else "Controls")
  home_button.text="" if size.x<380 else "Home"
  home_button.icon=null if size.x>=380 else load("res://assets/ui/back.svg")
  rect(bar,Vector2(10,size.y-66-safe_bottom),Vector2(size.x-20,54))
  var sheet_width:float=size.x-20 if portrait else minf(460,size.x*.6)
  rect(app.ui_side,Vector2(size.x-sheet_width-10,58+safe_top),Vector2(sheet_width,size.y-134-safe_top-safe_bottom))
  if not app.home_active and not is_instance_valid(app.training):rect(app.board_container,Vector2(0,55+safe_top),Vector2(size.x,size.y-127-safe_top-safe_bottom))
  app.mode_selector.visible=false
 else:
  app.mode_selector.visible=true
  app.ui_side.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);app.ui_side.anchor_left=.755;app.ui_side.offset_right=-26;app.ui_side.offset_top=108;app.ui_side.offset_bottom=-42
  if not app.home_active and not is_instance_valid(app.training):
   app.board_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);app.board_container.anchor_right=.76;app.board_container.anchor_top=.09;app.board_container.anchor_bottom=.96
 if app.home_active:app.board_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 app.piece_badges.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT);app.piece_badges.position=app.board_container.position;app.piece_badges.size=app.board_container.size
 var intro_width:=minf(size.x-24,560.0)
 rect(app.intro_panel,Vector2(12,size.y-190-safe_bottom),Vector2(intro_width,0))
 refresh()
