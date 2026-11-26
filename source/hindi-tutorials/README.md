# Guided Hinglish tutorials V2

The nine supplied Aoede V2 recordings replace V1. They already contain one pitch-preserving 1.25x adjustment; runtime playback stays at 1.0. The originals remain in audio/hinglish/v2 and older originals are retained separately. No recordings were regenerated, edited or sped up during integration. See timings.json for transcripts, durations and SHA-256 hashes.

Lessons demonstrate a legal move, reset their exercise position, and wait for the recording's instruction before enabling input. The cue is driven by actual playback position; muted/unavailable audio uses an elapsed-time fallback. Clip-local cue seconds: pawn 12.12, rook 12.68, bishop 15.60, knight 14.19, queen 12.02, king 12.99, castling 21.26, pin approximately 17.00, fork 10.17. These come from the supplied automated measured transcription; the pin passage lacks reliable word alignment, so its onset is approximate and should be checked by listening. No human listening approval is claimed.

Screen-space outlines, a pulsing ring and a connected callout identify the piece to tap, then outline allowed destination squares. These remain readable on mobile and do not intercept touches. Captures use coral, ordinary moves green. Next appears only after the learner completes the exercise. Replay restarts the guided sequence and recording together. Mute, exit, music restoration and original match restoration remain supported.

Launch shows a quiet loading indicator then Home. Only Play on a fresh match starts the cinematic; Settings, Learn and resumed matches bypass it. Web PWA packaging includes all new recordings.

Source snapshots: scripts go in game/scripts, tests in game/tests and ui SVGs in game/assets/ui. main.gd and loading_intro.html are in ../intro-camps. Visual checks cover 320x640, 414x896, 896x414 and 1280x800; preview_guided_v2.gd verifies startup routing and actual audio-position gating before capturing piece/destination prompts.

## Animated portraits and tutorial cinematics

The lesson panel now includes an independently lit live 3D portrait of the current piece, reusing the game's original model and attack/idle animations. Only one portrait model is active. It is framed responsively and has no repeating audio over narration. The board prompt includes a translucent round chess-symbol badge.

Demonstrations transition from board view to a side close-up and a frontal view, follow the existing animated legal move (and existing animal calls), then smoothly return to the board. Practice remains locked until the narration cue and camera return. Leaving or switching lessons kills the tutorial camera tween; demonstration moves still award no progress. Normal game cinematic settings are restored afterward.

Verified: elephant, camel and horse animation clips/call events, camera return before practice, exact lesson reset, no demonstration XP, exit during a shot, existing narration controls and mobile touch/layout checks. Native rendered views inspected; real-phone frame-rate/audio assessment remains a user-device check. Web loader and PWA checks pass.
