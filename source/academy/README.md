# Royal Academy homepage

The existing 3D battlefield, armies, banners and tents remain the home background. Academy is primary; returning learners continue at their first unfinished exercise. Free play, guided pin/fork challenges, and My Progress remain directly available. Settings is a compact icon and version text is removed from home.

Thematic stages: Padati (six piece exercises), Ashvarohi (castling), Yoddha (pin/fork). Senapati and Maharathi are clearly future content. These are thematic titles rather than claims of historical rank order.

academy_progress.gd stores unique completed exercise IDs in user://academy-progress.cfg. Each successful learner exercise awards 25 XP once; demonstrations award none. There are 225 XP across the nine current exercises. Progress is local to this device/browser and can be lost when site/app data is cleared. No cross-device account sync is implied. A save failure is reported in the lesson footer.

Source: copy home_menu.gd and academy_progress.gd into game/scripts. Updated main.gd is in ../intro-camps and board_training.gd in ../hindi-tutorials. preview_academy.gd exercises isolated test progress files, reload, duplicate awards, next lesson routing, real exercise completion persistence, and captures desktop/phone layouts. Those checks and web loader/PWA checks passed; images were inspected at 320x640, 414x896 and desktop.
