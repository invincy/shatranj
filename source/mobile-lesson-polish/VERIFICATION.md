# Mobile lesson polish — 2026-11-26

- Compact lower lesson panel, separate transparent 3D portrait overlapping its edge. Mesh bounds align portraits to a shared foot line. No gold backdrop.
- Closer tutorial board (distance 13.2), battlefield ambient fill raised from .25 to .48. Compact royal homepage keeps live battlefield.
- No automatic narration pause. Original V2 clips retained at pitch 1.0. Camera lead-in and return fit measured instruction onsets; demonstrations still take several seconds.
- Pin illustration keeps rules unchanged, demonstrates illegal sideways exposure, restores shield, and leaves the legal capture to the learner.
- Knight holds the L corner briefly, turns there, and approaches capture along the short leg. Tutorial camera shows both legs.

Validation: all nine narrated lessons reached practice by their cue plus one second, with no stream pause, unchanged pitch, restored practice FEN, no demonstration XP, and working top Next and interrupted exit. Knight tests passed eight directions, clearance, capture in both modes, undo/skip and animal cues. Computer regression and PWA/startup/loader checks passed. Rendered previews checked at 414×896, 320×640, 896×414 and 1280×800.

Physical Android playback and the installed-app WebGL failure were not verified here. This change does not claim a hardware-specific WebGL fix. Existing geometry is unchanged; model sculpting remains separate work.
