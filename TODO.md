# CSM Fight Karo Lite — delivery checklist

## Browser-only session boundary
- [x] Deliver the requested lightweight browser game with no required login, registration or payment system, and no backend, database, Supabase integration or online matchmaking.
- [x] Keep match state, round results, settings, custom dialogue, voice clips and uploaded face photos in the active page session only. Never upload personal photos or recordings and never write user data to localStorage, IndexedDB, a backend, a database or remote persistence; closing or reloading the page clears it.
- [x] Keep gameplay simulation local and use a branded game loader/title with a configured Web export preset.

## Locked team rosters and characters
- [x] Player 1 may select only from CSM Gang: CR, Lady Don, Shiva Fighter, 51, 52, 53, 2nd CR and Arabian Horse.
- [x] Player 2 or CPU may select only from Opposite Gang: Swapna Taker, COA, Chubby Cheeks and Cheshma Girl. Never mix the two teams; allow character selection before each match.
- [x] Give every fighter an individual cartoon identity, clothing/color scheme, placeholder/replacable face card and signature attack: CR—Chairman's Order; Lady Don—Don's Fury; Shiva Fighter—Shiva Strike; 51—Fifty-One Blast; 52—Fifty-Two Smash; 53—Fifty-Three Explosion; 2nd CR—Second Command; Arabian Horse—Arabian Charge; Swapna Taker—Dream Breaker; COA—Architecture Attack; Chubby Cheeks—Cheek Blast; Cheshma Girl—Laser Vision.
- [x] Provide readable idle, walk, punch, kick, jump, block, hit-reaction, victory and defeat action states, plus character-specific signature-special effects.

## Combat and match flow
- [x] Start fighters at 100 HP. Punch deals 9 damage, kick 15 and signature special 25; blocking reduces damage, and successful attacks build special energy.
- [x] Implement punch, kick, block, jump, special, health bars, special meters, round timer, hit detection, collision boundaries, knockback, victory/defeat, round transitions and match results.
- [x] Run best-of-three matches, with each round lasting 60 seconds. Include pause, restart and rematch.

## Modes and controls
- [x] Support local 1v1 on one keyboard; single-player versus an AI opponent selected from Opposite Gang, with Easy, Normal and Hard movement, attack, defense and special behavior; and Practice against a stationary opponent.
- [x] Preserve exact keyboard controls: P1 A/D move, W jump, F punch, G kick, S block, H special; P2 Left/Right move, Up jump, K punch, L kick, Down block, semicolon (`;`) special.
- [x] Provide touch controls on mobile; a 640×1000 real-renderer capture checks portrait layout.

## Customization, humor and audio
- [x] Let a player select a character, upload and preview a photo, adjust crop/position, apply, replace or remove it, with the image retained in page memory only.
- [x] Allow custom dialogue for each character and optional recorded voice clips; support adding/replacing/removing a recording and voice on/off without saving it beyond the session.
- [x] Trigger funny Telugu/Telugu-English dialogue on match start and combat events (punch, kick, special, low health, win and loss). Include the requested lines: “Orey, internal exam anukunnava?”, “Naa range veru ra!”, “First attendance veyyi ra!”, “Dheenamma, mass entry!”, “Side ivvu ra babu!”, “Pass avvadam kuda oka art ra!”, “Ayyayyo, debba padindhi!” and “Friendship cancelled ra!”.
- [x] Include original arcade background music, punch, kick, jump, special, victory and defeat sound effects, funny dialogue voice clips and sound on/off controls.

## Screens and presentation
- [x] Include the landing/main menu, character selection, face-card customization, game-mode selection, instructions/controls, battle arena, pause menu, victory and defeat screens, match results and character collection.
- [x] Expose these main-menu actions: PLAY NOW, CHARACTER COLLECTION, CUSTOMIZE FIGHTER, HOW TO PLAY and SETTINGS.
- [x] Use a polished indie-arcade look, not an admin dashboard: dark collegiate arcade arena; neon cyan/pink accents and purple gradients; bold typography; cartoon fighters and cards; glowing health bars; animated buttons; an arcade VS screen and countdown; smooth transitions; and lightweight special-attack particles, targeting efficient smooth 60-FPS play.

## Verification and release
- [x] Source verifier passed; the font/glyph diagnostic reported no errors or missing glyphs.
- [x] Real-renderer captures checked the branded menu, arena/HUD, VS screen, signature-hit frame and mobile portrait touch layout.
- [x] Native gameplay smoke action hit the selected opponent for exactly 25 damage with a full special meter and confirmed the special action remained active.
- [ ] Finish the browser Web export and exported-pack check.
- [ ] Save the managed project checkpoint and push the requested project to the authorized CSM Fight Karo GitHub repository (subject to repository access).
