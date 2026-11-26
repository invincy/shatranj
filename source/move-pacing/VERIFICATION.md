# Player move pacing and tutorial continuation

Learner moves use presentation speed .45; normal gameplay .75. Narrated demonstrations retain .9 to preserve continuous speech timing. Quick travel has a minimum .8 second base duration (about 1.78 seconds in practice and 1.07 in normal quick mode). Quick knight leaps use a 1-second base duration. World animation clips follow presentation speed; audio pitch and narration unchanged.

A gold floating completion button appears below the lesson selector only after the learner move finishes. It stays until tapped and resets on lesson changes; the final lesson offers Finish. The existing top Next control remains available.

Native rendered test passed practice duration, prompt hidden while moving, prompt bounds, explicit progression, next-lesson reset, normal quick/cinematic pace and undo. Computer behavior regression assertions passed (headless shutdown reported remaining objects/resources). Knight tests passed all eight directions, skip, undo, both capture modes and animal sounds. Web export, PWA and home-loader checks passed. Physical phone testing not performed.
