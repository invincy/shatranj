extends VBoxContainer
const Rules=preload("res://scripts/chess_rules.gd")
const LESSONS=[
 {"title":"1 · Pawn (प्यादा)","text":"Pawns move one square forward. From their starting square they may move two if both squares are empty. They capture one square diagonally forward, never straight ahead. On the last rank, promote to a queen, rook, bishop or knight. En passant is a special capture available immediately after an adjacent enemy pawn advances two squares.","fen":"k7/8/8/8/8/3p4/4P3/7K w - - 0 1","from":12,"targets":[20,28,19],"task":"Tap e2, then try a highlighted advance or the capture on d3."},
 {"title":"2 · Rook (हाथी)","text":"The Haathi moves any number of squares along a rank or file: horizontally or vertically. It cannot jump over another piece. Capture an enemy by landing on its square.","fen":"k7/8/8/8/3R4/8/8/7K w - - 0 1","from":27,"targets":[],"task":"Tap d4 and try any highlighted straight move."},
 {"title":"3 · Bishop (ऊँट)","text":"The Oont moves any number of squares diagonally. It cannot jump over pieces and always stays on the same colour of square.","fen":"k7/8/8/8/3B4/8/8/7K w - - 0 1","from":27,"targets":[],"task":"Tap d4 and try a diagonal move."},
 {"title":"4 · Knight (घोड़ा)","text":"The Ghoda moves two squares in one direction and one sideways: an L shape. It can jump over other pieces. It captures only on its landing square, never along the route.","fen":"k7/8/8/8/3N4/8/8/7K w - - 0 1","from":27,"targets":[],"task":"Tap d4 and find an L-shaped destination."},
 {"title":"5 · Queen (रानी)","text":"The Rani combines rook and bishop movement: any number of squares horizontally, vertically or diagonally. She cannot jump over pieces.","fen":"k7/8/8/8/3Q4/8/8/7K w - - 0 1","from":27,"targets":[],"task":"Tap d4 and try a straight or diagonal move."},
 {"title":"6 · King (राजा)","text":"The Raja moves one square in any direction, but never onto an attacked square. Kings cannot stand next to each other. When in check, you must escape check. Checkmate means there is no legal escape; the king is never captured.","fen":"k7/8/4r3/8/3K4/8/8/8 w - - 0 1","from":27,"targets":[],"task":"Tap d4. The rook on e6 attacks the e-file and sixth rank. Try a safe square."},
 {"title":"7 · Castling (कैसलिंग)","text":"Castling moves the king and rook together. Move your king two squares toward the rook; the rook moves to the square the king crossed. Neither may have moved before, all squares between them must be empty, and the king cannot start in check, cross check or finish in check. An attacked rook does not itself prevent castling.","fen":"4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1","from":4,"targets":[6,2],"task":"Tap e1, then g1 or c1. Watch the rook move too."},
 {"title":"8 · Pin (पिन)","text":"A pin ties a piece to something valuable behind it. Here the Haathi on e2 shields the Raja on e1 from the enemy rook on e8. This is an absolute pin: moving sideways would expose the king, so it is illegal. A relative pin protects a valuable piece other than the king; moving is legal but may lose material.","fen":"k3r3/8/8/8/8/8/4R3/4K3 w - - 0 1","from":12,"targets":[60],"task":"Tap e2. Notice that sideways moves are unavailable. Capture the pinning rook on e8."},
 {"title":"9 · Fork (फोर्क)","text":"A fork attacks two or more targets at once. Knights are especially good at this. In this position Nd5 attacks the king on c7 and rook on f6. Black must answer the check, giving White a chance to win the rook next.","fen":"8/2k5/5r2/8/8/2N5/8/6K1 w - - 0 1","from":18,"targets":[35],"task":"Move the knight from c3 to d5 to fork the king and rook."}
]
var available: Array[int]=[0,1,2,3,4,5,6,7,8]
var rules
var lesson_index:=0
var selected:=-1
var complete:=false
var completed: Dictionary={}
var cells: Array[Button]=[]
var picker: OptionButton
var explanation: Label
var details: Label
var feedback: Label
var progress: Label

func wrapped(text: String) -> Label:
 var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",15);return label

func _ready():
 add_theme_constant_override("separation",10)
 add_child(wrapped("Practice without changing your match."))
 picker=OptionButton.new();picker.custom_minimum_size.y=42
 for i in range(LESSONS.size()):picker.add_item(LESSONS[i].title,i)
 picker.item_selected.connect(func(index):load_lesson(picker.get_item_id(index)));add_child(picker)
 explanation=wrapped("");add_child(explanation)
 add_child(wrapped("White moves upward ↑. Tap the piece, then a green square."))
 var grid:=GridContainer.new();grid.columns=9;grid.add_theme_constant_override("h_separation",1);grid.add_theme_constant_override("v_separation",1);add_child(grid)
 cells.resize(64)
 for rank in range(7,-1,-1):
  var rank_label:=Label.new();rank_label.text=str(rank+1);rank_label.custom_minimum_size.x=12;grid.add_child(rank_label)
  for file in range(8):
   var square:=rank*8+file;var button:=Button.new();button.custom_minimum_size=Vector2(25,32);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   button.add_theme_color_override("font_outline_color",Color("26332e"));button.add_theme_constant_override("outline_size",2);button.add_theme_font_size_override("font_size",18);button.pressed.connect(tap.bind(square));grid.add_child(button);cells[square]=button
 grid.add_child(Label.new())
 for file in "abcdefgh":
  var file_label:=Label.new();file_label.text=file;file_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;grid.add_child(file_label)
 feedback=wrapped("");add_child(feedback)
 var actions:=HBoxContainer.new();add_child(actions)
 var reset:=Button.new();reset.text="Try again";reset.custom_minimum_size.y=42;reset.pressed.connect(func():load_lesson(lesson_index));reset.size_flags_horizontal=Control.SIZE_EXPAND_FILL;actions.add_child(reset)
 var next:=Button.new();next.text="Next lesson";next.custom_minimum_size.y=42;next.pressed.connect(func():load_lesson(available[(available.find(lesson_index)+1)%available.size()]));next.size_flags_horizontal=Control.SIZE_EXPAND_FILL;actions.add_child(next)
 progress=wrapped("");add_child(progress)
 details=wrapped("");add_child(details)
 add_child(wrapped("K king · Q queen · R rook · B bishop · N knight · P pawn. Lowercase letters are Black / Emerald."))
 add_child(wrapped("More lessons planned: openings, development and king safety."))
 load_lesson(0)

func set_category(category:String):
 available.assign([0,1,2,3,4,5,6] if category=="basics" else [7,8])
 picker.clear()
 for index in available:picker.add_item(LESSONS[index].title,index)
 load_lesson(available[0])

func load_lesson(index: int):
 lesson_index=index;picker.select(available.find(index));rules=Rules.new(LESSONS[index].fen);selected=-1;complete=false
 explanation.text=LESSONS[index].text.split(". ")[0]+".";details.text="HOW IT WORKS\n"+LESSONS[index].text;feedback.text=LESSONS[index].task;paint()

func tap(square: int):
 if complete:return
 var lesson:Dictionary=LESSONS[lesson_index]
 if square==lesson.from:
  selected=square;feedback.text=lesson.task;paint();return
 if selected<0:
  feedback.text="First select "+Rules.square_name(lesson.from)+".";return
 var legal:=false
 for move in rules.legal_moves(selected):
  if move.to==square:legal=true
 if not legal:
  feedback.text="That move is not legal. Choose a highlighted square.";return
 if not lesson.targets.is_empty() and square not in lesson.targets:
  feedback.text="Legal move, but try the lesson goal: "+lesson.task;return
 rules.play(selected,square);selected=-1;complete=true;completed[lesson_index]=true
 feedback.text="Well done! "+("The king and rook have both moved." if lesson_index==6 else ("The knight now attacks c7 and f6." if lesson_index==8 else "You completed this exercise."));paint()

func paint():
 var destinations: Array=[]
 if selected>=0:
  for move in rules.legal_moves(selected):destinations.append(move.to)
 for square in range(64):
  var cell:Button=cells[square];var piece:String=rules.board[square]
  cell.text=piece if piece!="" else "·"
  cell.tooltip_text=Rules.square_name(square)+(" — "+piece if piece!="" else "")
  var style:=StyleBoxFlat.new();style.bg_color=Color("52645e") if (square%8+square/8)%2==0 else Color("c9c2ad")
  if square in destinations:style.bg_color=Color("5d927e")
  style.border_color=Color("e6ba68");style.set_border_width_all(3 if square==selected else 0)
  style.content_margin_left=0;style.content_margin_right=0
  cell.add_theme_stylebox_override("normal",style);cell.add_theme_stylebox_override("hover",style)
  cell.add_theme_color_override("font_color",Color("ffffff") if Rules.side(piece)=="w" else Color("0c1719"))
 progress.text=str(completed.size())+" / "+str(LESSONS.size())+" exercises completed this session."
