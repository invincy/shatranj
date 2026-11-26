extends Node
## The supplied Hinglish V2 Aoede clips already contain one pitch-preserving 1.25x speedup.
## Always play them at 1.0. Do not synthesize or speed them up again.
const FILES = ["01_pawn", "02_rook", "03_bishop", "04_knight", "05_queen", "06_king", "07_castling", "08_pin", "09_fork"]
static var muted := false
var player: AudioStreamPlayer
var sound: Node
var paused_music := false

func _ready() -> void:
 player = AudioStreamPlayer.new()
 player.pitch_scale = 1.0
 add_child(player)
 player.finished.connect(_restore_music)

func play_lesson(index: int) -> bool:
 stop()
 if muted or (is_instance_valid(sound) and sound.muted): return false
 if index < 0 or index >= FILES.size(): return false
 var path: String = "res://assets/audio/hindi/" + FILES[index] + ".mp3"
 if not ResourceLoader.exists(path): return false
 var stream = load(path) as AudioStreamMP3
 if stream == null: return false
 player.stream = stream
 player.pitch_scale = 1.0
 if is_instance_valid(sound) and is_instance_valid(sound.music_voice):
  paused_music = sound.music_voice.playing and not sound.music_voice.stream_paused
  if paused_music: sound.music_voice.stream_paused = true
 player.play()
 return true

func set_muted(value: bool) -> void:
 muted = value
 if muted: stop()

func stop() -> void:
 if is_instance_valid(player):
  player.stop()
  player.stream = null
 _restore_music()

func _restore_music() -> void:
 if paused_music and is_instance_valid(sound) and is_instance_valid(sound.music_voice):
  sound.music_voice.stream_paused = false
 paused_music = false

func _exit_tree() -> void:
 stop()
