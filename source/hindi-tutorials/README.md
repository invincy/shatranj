# Hindi tutorial narration integration

Nine Aoede Hindi recordings are bundled inside the game pack, in lesson order: pawn, rook, bishop, knight, queen, king, castling, pin, fork. The original 1.25x pitch-preserving adjustment is already in the files. Godot plays at pitch_scale 1.0; do not apply another speed adjustment.

Entering or changing a lesson plays its matching clip. Listen again restarts that clip. Mute voice persists for the current game session. Retry restarts narration unless muted. Back stops narration immediately. Existing Mute all is respected. Music pauses while narration plays and resumes afterward. Written instructions remain available if audio cannot load. The clips cache offline with the complete game pack.

This directory preserves the changed Godot source for review and future builds. In the original development checkout, copy board_training.gd and lesson_voice.gd to game/scripts/, test_lesson_voice.gd to game/tests/, and the nine unchanged MP3s to game/assets/audio/hindi/. See timings.json for filenames, source transcripts, durations, and SHA-256 hashes. Build with the existing Web export and prepare_web.py workflow.

## Validation and release status

Godot narration lifecycle, nine clip mappings and measured durations, existing 3D training exercises, and mobile-layout tests pass. Web export, compressed loader, split pack integrity, and offline cache checks pass. Native rendered layout checked at 1280x800, 414x896, 896x414 and 320x640; voice controls remain outside the scrolling text.

Listening review remains pending with the owner, especially 07_castling.mp3: automatic transcription was inconsistent. Real mobile browser audible playback also remains an owner check. On 2026-11-25 the owner requested deployment after technical verification and will review the audio afterward; neither listening nor real-device audibility is claimed as passed. No existing exercise position or spoken coordinate was changed.

Review rerun on 2026-11-25: narration lifecycle, training exercises, mobile layout, web loader, split pack, PWA/offline packaging and home loader checks passed. All nine bundled source MP3s match the supplied recordings and their SHA-256 hashes; the ZIP passes integrity checking. Tested Godot source matches the PR source. Timing metadata matches the pack except for omitted Creator Studio project identifiers. Playback remains 1.0 with no regeneration or extra speed adjustment.

## Demonstrate, then practise

Each lesson now highlights and animates a legal example before resetting the lesson board for the learner. Input is blocked during the demonstration; only a learner move counts as completion. Next appears after successful practice; the final lesson offers Finish. Leaving or changing lessons invalidates pending demonstration callbacks. Muting does not block progression. Compact icon controls provide home, replay narration, voice mute, replay demonstration, and a zoom menu. Existing recordings still play at 1.0 without modification.

Validation: all nine automatic demonstrations reset to the exact original FEN and unlock practice; legal/illegal input, castling, pin, fork, match restoration, mobile touch projection, narration lifecycle and offline web packaging pass. Rendered layout inspected at 320x640, 414x896, 896x414 and 1280x800. Copy the SVGs in ui/ to game/assets/ui/ when rebuilding from these source snapshots.
