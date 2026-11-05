# CSM Fight Karo Lite — Implementation Plan

## Product scope and architecture

Build the requested 2D side-view arcade fighting game in the initialized Godot 4.7.2 Game project and ship it through the existing static Godot Web export pipeline. Preserve the generic starter's functioning Web export, browser loading mechanics, audio routing, theme fonts, preview identity, and release/save pipeline, while replacing the inherited maze gameplay and source-game branding. The game is offline and local-only: do not add server, database, Supabase, login, analytics persistence, or remote services. Keep selections, match score, settings, and uploaded photos in memory only for the current active browser session. Never write personal photos or gameplay data to localStorage, IndexedDB, a backend, or a database, and never send photos off-device.

The flow is a branded main menu into mode/character selection, then a best-of-three arena, pause/round transitions, and results with rematch/reselect/menu actions. Player 1 only picks from the eight named CSM Gang characters; Player 2/CPU only picks from the four Opposite Gang characters. Local 1v1, CPU (Easy/Normal/Hard), and Practice share the same combat model and presentation. A touch HUD complements the specified keyboard maps.

### Project structure

- `scenes/main.tscn`: retain the single Godot Web boot scene; use a control-root UI with a custom-drawn side-view battle surface.
- `scripts/main.gd`: navigation/state owner, page construction, in-memory settings/customization, key/touch input, HUD binding, audio cues, and match flow.
- `scripts/game/fighter_roster.gd`: authoritative team partitions, all 12 character descriptions/colors/signature names and dialogue pools.
- `scripts/game/fight_rules.gd`: combat actions, 60-second timer, collision bounds, damage/block/energy rules, rounds and AI decision policy.
- `scripts/entities/fighter_actor.gd`: custom lightweight cartoon fighter drawing and presentation states (idle, move, jump, attack, block, hit, special, victory, defeat); visual motion never decides damage.
- `assets/game/`: selected AI-generated, properly licensed game art and compressed original music/effect assets; no personal-user imagery.
- `assets/share/`: game-specific favicon referenced by `game-sharing.json` and the lightweight Web loading screen.
- `web/loading.html`: branded solid-color CSM Fight Karo loader with live progress, status, retry, reduced-motion and a game-specific favicon; no inherited maze/runner art.
- `project.godot`: correct game title, one main locale (English UI with requested Romanized Telugu dialogue), browser viewport, no saved/OS/browser automatic language switching, and no durable gameplay/photo state.

## Design description

**Design Movement:** Indie neon arcade collage, with comic-book impact marks and chunky cartoon silhouettes over a dark collegiate arena.

**Core Principles:** readable team identity at a glance; playful exaggerated character shapes; actions and damage communicate immediately; UI stays lightweight and easy to navigate.

**Color Philosophy:** charcoal and midnight purple backgrounds make the cyan CSM accents and hot-pink opposing accents feel electric and competitive without reducing readability; amber/lime effects reserve high contrast for impact, energy, and the fight call-to-action.

**Layout Paradigm:** asymmetric arcade cabinet framing: a bold left-anchored menu, opponent/team color on the opposite side, a wide stage in the middle, and fighter-focused health/energy bars at the edges; selection cards adapt to narrow screens and touch targets move into an accessible lower control rail.

**Signature Elements:** split cyan-versus-pink team rails; comic burst rings and impact slashes; a campus chalkboard/attendance motif used sparingly in live UI details.

**Interaction Philosophy:** immediate start-to-fight flow, conspicuous focus and readiness states, no account/setup friction, touch and keyboard equivalents, and a clear pause/restart/rematch path.

**Animation:** short readable idle bob and walk cycles, brief telegraph before attacks, lunge/limb extension and impact pause/knockback, limited particle bursts for specials, subtle screen accents, and reduced-motion-safe alternatives; never drive hit detection from effects.

**Typography System:** use the bundled Sora display resources for arcade titles and the bundled Figtree UI family for all gameplay text. Keep the requested Telugu dialogue in its provided Latin transliteration; all interface labels remain live text rather than baked into generated art.

**Brand Essence:** a local-only CSM college-friends arcade brawler that turns attendance jokes into a quick playable rivalry; mischievous, punchy, communal.

**Brand Voice:** energetic and teasing, like friends trading campus one-liners. Example headlines: “FRIENDS BY DAY. ENEMIES IN THE ARENA.” and “Attendance ledu. Mercy kuda ledu.”

**Wordmark & Logo:** live CSM FIGHT KARO lettering with a compact split lightning/VS glyph, cyan and pink halves, and a small LITE plate; do not rely on generated image text.

**Signature Brand Color:** electric cyan `#43E9FF`, paired with hot pink for opponents.

## Material constraints

Do not add backend services or permanent client storage. Keep the existing resource/build/export path and template license material. Reuse the current audio routing and browser-safe background music adapter. All new gameplay art is original AI-generated or simple engine-drawn, and all audio is original/generated or procedurally created; keep personal uploads in memory and do not mix them into project content.