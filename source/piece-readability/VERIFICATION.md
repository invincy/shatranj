# Match piece readability

Added a non-shadowing soft fill light masked to character meshes only; terrain and board retain existing lighting. Front preset now uses 54 degrees/13.2 distance on compact displays and 36 degrees/14 distance on desktop to reduce rank overlap. Manual camera controls remain available.

Small role badges retain projected-square sizing and opacity control, but sit slightly in front of each piece, use a faint dark backing, and gain icon contrast. Selecting a piece shows its English/Hindi name and square in the compact top bar; deselection restores turn status.

Native rendered checks at 414×896, 320×640 and 1280×800; piece-only light layer, selected name/deselection, preset framing and unchanged match assertions passed. Player UI regression passed opacity control, developer mode switching, match preservation, skip/undo and camera tilt. Web export, PWA and home-loader checks passed. No physical phone performance check. Existing character geometry, tutorial framing, narration and move speeds preserved.
