extends SceneTree
var failures := 0
func check(ok: bool, title: String):
 if ok: print("PASS ", title)
 else: failures += 1; push_error(title)
func _initialize(): call_deferred("run")
func run():
 var app = load("res://scripts/main.gd").new()
 app.intro_enabled = false
 root.add_child(app)
 await process_frame
 app.sound.muted = false
 app.sound.music_enabled = true
 app.sound._update_music()
 app._begin_training("basics")
 var training = app.training
 check(training.voice.player.playing, "entering training starts pawn narration")
 check(app.sound.music_voice.stream_paused, "background music pauses during narration")
 var durations = [20.199, 17.326, 19.428, 17.765, 16.051, 17.829, 27.533, 22.823, 18.674]
 for index in range(7):
  training.load_lesson(index)
  check(training.voice.player.stream.resource_path.ends_with(training.LessonVoice.FILES[index] + ".mp3"), "correct clip for basic lesson " + str(index))
  check(abs(training.voice.player.stream.get_length() - durations[index]) < 0.15, "clip has complete measured duration " + str(index))
  check(training.voice.player.pitch_scale == 1.0, "no duplicate speed adjustment " + str(index))
 training.voice_mute.button_pressed = true
 check(not training.voice.player.playing and not app.sound.music_voice.stream_paused, "mute stops speech and restores music")
 training.load_lesson(0)
 check(not training.voice.player.playing, "lesson change respects voice mute")
 training.voice_mute.button_pressed = false
 training.play_narration()
 check(training.voice.player.playing, "replay starts current lesson after unmute")
 training.load_lesson(0)
 check(training.voice.player.get_playback_position() < 0.2, "retry restarts from beginning")
 var old_voice = training.voice
 app._show_home()
 check(not old_voice.player.playing and not app.sound.music_voice.stream_paused, "Back stops narration immediately and restores music")
 app._begin_training("tactics")
 training = app.training
 for index in [7, 8]:
  training.load_lesson(index)
  check(training.voice.player.stream.resource_path.ends_with(training.LessonVoice.FILES[index] + ".mp3"), "correct clip for tactic " + str(index))
  check(abs(training.voice.player.stream.get_length() - durations[index]) < 0.15, "complete tactic recording " + str(index))
 training.voice.player.finished.emit()
 check(not app.sound.music_voice.stream_paused, "natural completion restores music")
 check(not training.voice.play_lesson(99) and not training.voice.player.playing, "invalid lesson fails without stale narration")
 app.sound.muted = true
 training.play_narration()
 check(not training.voice.player.playing, "existing Mute all is respected")
 app.queue_free()
 await process_frame
 print("LESSON_VOICE_TESTS_COMPLETE failures=", failures)
 quit(failures)
