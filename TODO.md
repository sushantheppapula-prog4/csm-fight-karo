# CSM Fight Karo Lite — completed acceptance checklist

## Browser-only session boundary
- [x] Deliver a lightweight, responsive browser fighting game with no required login, registration, payment, backend, database, Supabase integration or online matchmaking.
- [x] Keep match state, results, settings, custom dialogue, voice clips and uploaded face photos only in the active page session; never upload personal photos or write user data to localStorage, IndexedDB, a backend, a database or remote persistence. Closing/reloading ends the session data.

## Locked teams and characters
- [x] Player 1 selects only from CSM Gang: CR, Lady Don, Shiva Fighter, 51, 52, 53, 2nd CR and Arabian Horse.
- [x] Player 2 or CPU selects only from Opposite Gang: Swapna Taker, COA, Chubby Cheeks and Cheshma Girl. Never mix teams; select before each match.
- [x] Give every fighter a unique cartoon look, color/clothing identity, editable face card and signature: CR—Chairman's Order; Lady Don—Don's Fury; Shiva Fighter—Shiva Strike; 51—Fifty-One Blast; 52—Fifty-Two Smash; 53—Fifty-Three Explosion; 2nd CR—Second Command; Arabian Horse—Arabian Charge; Swapna Taker—Dream Breaker; COA—Architecture Attack; Chubby Cheeks—Cheek Blast; Cheshma Girl—Laser Vision.
- [x] Implement readable idle, walk, punch, kick, jump, block, hit reaction, victory and defeat states, plus individual special-attack effects.

## Combat and match flow
- [x] Start each fighter at 100 HP; punch deals 9, kick 15 and signature special 25. Blocking reduces damage, and successful hits build special energy.
- [x] Support punch, kick, block, jump, special, health bars, energy meters, round timer, hit detection, boundaries/collisions, knockback, win/loss, round transitions and results.
- [x] Play best-of-three matches with 60 seconds per round, pause, restart and rematch.

## Modes and controls
- [x] Include same-keyboard local 1v1; single-player versus an Opposite Gang AI with Easy/Normal/Hard movement, attacks, defense and specials; and Practice against a stationary opponent.
- [x] Preserve the requested controls exactly: P1 A/D move, W jump, F punch, G kick, S block, H special; P2 Left/Right move, Up jump, K punch, L kick, Down block, semicolon (`;`) special.
- [x] Provide touch controls. A real-renderer 640×1000 capture checks the portrait layout.

## Customization, humor and audio
- [x] Select a fighter, upload and preview a face photo, adjust its crop/position, apply, replace or remove it; keep the photo in page memory only.
- [x] Allow per-character custom dialogue and optional voice recordings with add/replace/remove controls; keep clips in memory and clear them at session end.
- [x] Trigger Telugu/Telugu-English banter for start, punch, kick, special, low health, win and loss. Include “Orey, internal exam anukunnava?”, “Naa range veru ra!”, “First attendance veyyi ra!”, “Dheenamma, mass entry!”, “Side ivvu ra babu!”, “Pass avvadam kuda oka art ra!”, “Ayyayyo, debba padindhi!” and “Friendship cancelled ra!”.
- [x] Include original arcade background music, punch, kick, jump, special, victory, defeat and voice-quip audio, with sound controls.

## Screens and presentation
- [x] Implement main menu, character selection, face-card customization, mode selection, instructions/controls, battle arena, pause, victory, defeat, match results and character collection.
- [x] Main-menu actions: PLAY NOW, CHARACTER COLLECTION, CUSTOMIZE FIGHTER, HOW TO PLAY and SETTINGS.
- [x] Use the approved indie-arcade style: dark collegiate arena, cyan/pink neon and purple gradients, bold type, cartoon fighter cards, glowing health bars, animated buttons, VS screen and countdown, smooth transitions and lightweight special particles; target efficient smooth 60-FPS play.

## Verification
- [x] `npm run check` source verification passed; the font check reported zero errors and zero missing glyphs.
- [x] Real-renderer menu, VS, arena/HUD, special-hit and mobile portrait captures were inspected; the native special-hit smoke assertion confirmed exactly 25 damage.
- [x] The prepared browser Web build and `npm run check -- --pack` succeeded for the final candidate. Runtime art/audio binaries remain in the project's managed asset store; the website bundle is prepared through the project release pipeline.
