# AGENTS.md — LAST EDGE

Instructions for AI coding agents (OpenCode, Claude Code, others) working on this repo.
Read this file fully before changing anything. The game design and roadmap are in
**PLAN.md**. This file covers how the code works and how to work on it.

## What this is

LAST EDGE: a 2D action roguelite (fast sword combat, lit pixel art) in **Godot 4.7 +
GDScript**, with online 2-player co-op planned. Target platforms: Steam (Windows/Linux),
Android and iOS.

## Commands (run from the repo root)

```bash
# Re-import after adding files or a new class_name (refreshes the global class cache)
godot --headless --path . --import

# Unit tests (must pass before you finish any task; exit code 1 = failure)
godot --headless --path . -s res://tests/run_tests.gd

# Run the game headless for 10 game seconds to catch runtime errors
godot --headless --path . --fixed-fps 60 --quit-after 600

# Bot/scripted playtests with an event log (scenarios: combo, hound, drone, ledge, slam, linked, ninja, brawl)
godot --headless --path . --fixed-fps 60 --quit-after 480 -- --demo=hound

# Same, recorded to PNG frames you can look at
godot --path . --write-movie /tmp/frames/f.png --fixed-fps 60 --quit-after 480 -- --demo=hound

# See the whole sandbox map zoomed out (record 5 frames and look at the last one)
godot --path . --write-movie /tmp/overview/f.png --fixed-fps 60 --quit-after 5 -- --overview

# Regenerate the code-made art after editing the scripts
tools/art/.venv/bin/python tools/art/generate_sandbox_art.py   # terrain tiles, rain
tools/art/.venv/bin/python tools/art/generate_level_art.py     # facades, props, foreground

# AI backdrop layers (local Stable Diffusion XL on the Mac GPU; ~7 GB model cached once):
# generate raw candidates, look at tools/art/raw/, then process the chosen seeds
tools/art/.venv/bin/python tools/art/generate_ai_backgrounds.py far --count 3
tools/art/.venv/bin/python tools/art/process_backgrounds.py --pick far=1101 mid=2202 near=3303

# 3D-to-pixel sprites: model + animate by script in Blender, then pack the sheet
/Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/models/hound.py
tools/art/.venv/bin/python tools/art/make_spritesheet.py hound

# Regenerate the pixel font (glyphs are drawn in the script)
tools/art/.venv/bin/python tools/art/generate_font.py

# Regenerate all sound effects and music (synthesized; deterministic)
tools/art/.venv/bin/python tools/audio/generate_audio.py

# Record a scenario with sound as a video (frames + audio → mp4)
godot --path . --write-movie /tmp/v/f.png --fixed-fps 60 --quit-after 420 -- --demo=combo
ffmpeg -framerate 60 -i /tmp/v/f%08d.png -i /tmp/v/f.wav -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest /tmp/v/combo.mp4

# Convert any image (e.g. AI output) to game pixel art with the game palette
tools/art/.venv/bin/python tools/art/pixelize.py IN.png OUT.png --height 48 --outline

# First time only: create the Python environment for the art tools
python3 -m venv tools/art/.venv && tools/art/.venv/bin/pip install pillow torch diffusers transformers accelerate safetensors

# Re-apply project settings (display, physics layers, input map, autoloads)
godot --headless --path . -s res://dev/configure_project.gd

# Open the editor / play
godot --path . --editor
godot --path .
```

**Always pass `--fixed-fps 60` to headless runs.** Without it, game time follows the wall
clock and `--quit-after` frames finish long before the game time you expect.

A task is done only when: the tests pass, the headless run prints no new errors or
warnings, and (for gameplay changes) a demo scenario log or recording shows it working.
Add or extend a demo scenario in `dev/demo_driver.gd` for new combat features.

## Hard rules

1. **Typed GDScript everywhere** (`var speed: float = 200.0`, `func f(x: int) -> void`).
   Tabs for indentation. snake_case files and functions, PascalCase classes and nodes.
2. **Never put tuning numbers in code.** Player numbers go in `PlayerTuning` resources
   (`characters/<name>/<name>_tuning.tres`), enemy numbers in `EnemyData` resources
   (`enemies/<name>/<name>_data.tres`). New systems get their own Resource class.
3. **Timing is measured in game time, never by counting physics ticks.** Frame data is
   written in 60 fps frames and converted with `FrameTime.seconds(frames)`; accumulate
   `delta` and compare (see `Player._past()`, `EnemyBase.state_past_frames()`). During
   Focus slow motion Godot still runs 60 ticks per real second and only shrinks `delta`,
   so counted ticks would ignore slow motion.
4. **Physics layers:** use the `Layers` constants (`core/util/layers.gd`), never raw
   numbers in code. In `.tscn` files use the bit values (layer N = `1 << (N-1)`). Keep
   `Layers`, `PHYSICS_LAYERS` in `dev/configure_project.gd`, and PLAN.md section 26 in sync.
5. **Project settings:** change display/physics/input/autoload settings in
   `dev/configure_project.gd` and re-run it. Don't hand-edit those sections of `project.godot`.
6. **Randomness that affects gameplay** (level generation, loot, enemy choices) must use
   `RunState.rng.stream(&"name")`, never `randi()`/`randf()`. Co-op and daily runs depend
   on both players generating identical results from the same seed. Visual-only effects
   (shake, particles) use their own local `RandomNumberGenerator`.
7. **Networking authority** (PLAN.md section 28): the host (peer 1) owns enemies, level
   state and loot; each player owns their own character. Gameplay code checks
   `is_multiplayer_authority()` before simulating. `Feel` (hit freeze, shake, slow
   motion) is local only.
8. **Saves:** only through `JsonStore` + `ProfileSchema`. If you change the profile shape,
   bump `ProfileSchema.VERSION`, add a migration step, and add a test.
9. **Every logic change gets unit tests** in `tests/unit/test_*.gd` (see "Tests" below).
10. **Autoload scripts have no `class_name`** (the autoload name is the global).
11. **Original IP only.** No names, art, music or text from other games (Katana ZERO,
    Dead Cells, etc.). No secrets in the repo (keystores, API keys, EOS credentials).
12. **Keep PLAN.md checklists current**: tick items in section 36 when they're done, and
    update "Current status" below.

## Godot 4.7 gotchas we've hit

- Don't name methods `_set`, `_get`, `_init` etc. unless overriding: they're Object
  virtuals (`_set` caused a parse error in the setup script).
- After adding a script with a new `class_name`, run `--import` before `-s` scripts or
  tests can see it.
- Physics interpolation is on: call `reset_physics_interpolation()` after teleporting a
  node (see `Player._respawn`). `Camera2D` must use `process_callback = 0` (physics).
- `Engine.time_scale` doesn't slow the physics tick rate (see rule 3).
- `Input.action_press()` called during a physics frame only counts as "just pressed" on
  the **next** physics frame, so scripted input (the demo bot) reacts one frame late.
  Bots must anticipate (e.g. parry at the end of a wind-up), like a human reading a telegraph.
- `JSON.parse_string` returns numbers as floats: wrap with `int()` when reading counts.
- Use `TileMapLayer` (not the deprecated `TileMap`) for rooms.
- A `--write-movie` run that quits while a sound plays prints one or two "leaked
  AudioStreamPlaybackWAV" lines at exit. Harmless.
- `Gradient`: set the colors of both ends (`set_color(0/1)`) **before** `add_point()`;
  adding a point re-sorts the indexes, so a later `set_color(1, ...)` changes the wrong point.
- Signals declared on the `Events` bus are wrapped in `@warning_ignore_start("unused_signal")`.
- The pixel font is a bitmap font imported with integer scaling (`scaling_mode=1` in
  `art/fonts/last_edge.fnt.import`): use font sizes 8, 16 or 24 only, and never scale
  Labels (tween colors or positions to make text pop). Outlines don't render on bitmap
  fonts; the theme gives every Label a 1 px shadow instead. Text is all caps (lowercase maps
  to capitals); add missing characters to `GLYPHS` in the generator.

## Architecture map

| Path | What it is |
|---|---|
| `project.godot` | Engine settings (generated by `dev/configure_project.gd`) |
| `autoload/events.gd` | Global signal bus (`Events`) |
| `autoload/game.gd` | Game mode + scene changes (`Game.goto(&"id", mode)`); scene ids in `SCENES` |
| `autoload/settings.gd` | Player settings in `user://settings.cfg` (`Settings.get_value`) |
| `autoload/save_service.gd` | Save file paths (profile, current run) |
| `autoload/profile.gd` | Permanent progress dictionary (`Profile.data`) |
| `autoload/run_state.gd` | Current run: seed, Threat Level, RNG streams |
| `autoload/net.gd` | Co-op sessions (LAN/ENet now, EOS later) |
| `autoload/audio.gd` | `Audio.play(&"name", volume_db)`, `play_music()`, `play_ambience()`; buses Music/SFX/Ambience; silent in headless runs |
| `audio/` | `sfx/*.wav` and `music/*.wav`, generated by `tools/audio/generate_audio.py` |
| `autoload/feel.gd` | Local game feel: hit freeze, shake, slow motion, screen flash, and one-shot effects (`impact` sparks + cut mark + light, `death_burst` scrap + oil, `damage_number`, `ring`, `dust`, `afterimage`) |
| `core/components/` | `HitboxComponent`, `HurtboxComponent`, `ResolveComponent` (player pips), `HealthComponent`, `PostureComponent`, `FocusComponent` |
| `core/damage/damage_info.gd` | One hit's data + result flags (`executed`, `killed`) set by the target |
| `core/state_machine/` | Generic `StateMachine` + `MachineState` (for complex bosses later) |
| `core/save/` | `JsonStore` (atomic JSON + backup), `ProfileSchema` (defaults + migrations) |
| `core/util/` | `Layers`, `RngStreams`, `FrameTime` |
| `characters/player/` | `Player` controller + scene, `PlayerTuning` resource class |
| `characters/ronin/` | Ronin tuning values |
| `enemies/base/` | `EnemyBase` (shared enemy behaviour) + `EnemyData` resource class |
| `enemies/hound/` | Hound: approach → telegraph → lunge (parry practice) |
| `enemies/patrol_drone/` | Patrol Drone: hover, telegraph, fire bolts (deflect practice) |
| `enemies/linked_citizen/` | Linked Citizen: human, hits never kill; staggered → execute (slash) or free (hold Interact) |
| `enemies/training_dummy/` | Practice target (posture, execution, reset) |
| `combat/projectiles/` | `Projectile`: hits players; deflectable back at enemies |
| `game/arena/test_arena.gd` | `TestArena`: builds the sandbox from an ASCII map (legend at the top of the file); `marker(&"x")` gives marker positions |
| `game/arena/maps/sandbox.txt` | The multi-level sandbox map. Edit it directly; `test_sandbox_map.gd` checks it |
| `game/arena/level_dressing.gd` | `LevelDressing`: facade back wall (skyline + alleys), floor props, foreground silhouettes (Parallax2D); visual only |
| `game/arena/auto_tile.gd` | `AutoTile`: picks tileset tiles (edges, corners, variants, platform caps) from map neighbours |
| `game/fx/level_light.gd` | `LevelLight` (map `*` warm lamp, `+` teal neon, `!` red warning): fixture, halo, PointLight2D and a painted additive light pool |
| `game/background/atmosphere.gd` | Screen-space ground fog (`game/fx/fog.gdshader`) and vignette (`game/fx/vignette.gdshader`) between the world and the HUD |
| `game/background/parallax_backdrop.gd` | Screen-space parallax: 3 AI city layers (`art/backgrounds/ai_*.png`) + rain behind the world |
| `art/` | Game art: `tiles/`, `backgrounds/`, `fx/`, `sprites/` (PNG + JSON sheets), `source/mixamo/` (raw FBX, never shipped) |
| `game/fx/sprite_sheet.gd` | `SpriteSheet`: builds SpriteFrames from `art/sprites/<name>.png` + `.json` |
| `game/fx/sword_trail.gd` | `SwordTrail`: additive glowing sweep along the real blade (from the sheet's `blade_base`/`blade_tip` tracks); `heat` rises with the combo |
| `game/fx/fire_blade.gd` | `FireBlade`: the burning katana (smoke, flames licking up the blade, swing fire left in the air while attacking, embers, molten core, flickering firelight); `Player.fire_blade` toggles it |
| `game/fx/corpse_piece.gd` | `CorpsePiece`: remains of a dead machine (RigidBody2D, visual only): `slice()` cuts a sprite frame in two along the killing swing, `throw()` tumbles it whole; blink + scrap pop after `EnemyData.corpse_time` |
| `game/fx/slice.gdshader` | Draws one side of a cut sprite frame with a glowing, cooling cut edge (frame region passed as a uniform) |
| `game/fx/flash.gdshader` | Sprite tint shader: hit flash, wind-up blink, stagger tint |
| `tools/blender/` | `sprite_render.py` (shared helpers) + `models/<name>.py` (one script per character: model, poses, render) |
| `tools/art/` | Art tools: `palette.gpl`, `pixelize.py`, `generate_sandbox_art.py` (Python + Pillow, venv in `tools/art/.venv`) |
| `game/camera/camera_rig.gd` | Follow camera: close pixel-perfect zoom (`target_visible_height`, default 240 px), look-ahead, looks down while falling, trauma shake, overview mode |
| `game/hazards/spikes.gd` | Spike hazard (example of an always-on hitbox) |
| `game/boot/` | First scene → test arena for now |
| `ui/hud/hud.gd` | `Hud`: vitals plate, combo counter + ranks, controls panel (fades after `HELP_TIME`, toggle with `help` = H/F1), slow-mo tint, screen flash |
| `ui/hud/hud_vitals.gd` | `HudVitals`: Resolve pips (diamonds) + Focus bar, drawn in `_draw()` (no textures); shakes and flashes on lost pips |
| `ui/theme/game_theme.tres` | Project theme (`gui/theme/custom`): the pixel font for every Label, size 8, 1 px drop shadow |
| `art/fonts/` | The "Last Edge" pixel font (BMFont), generated by `tools/art/generate_font.py` |
| `tests/` | Test runner + `TestCase` base + `unit/` tests |
| `dev/` | Setup script + `demo_driver.gd` (scripted input + reactive bot + event log) |

### How a hit flows

```
Attacker's HitboxComponent (active during attack frames, process_hits() each frame)
  → build_damage Callable creates a DamageInfo
  → target HurtboxComponent.receive(info)   (refused if invulnerable)
  → HurtboxComponent.received signal → the target entity applies it:
       Player: parry window from the front → attacker.on_parried(); guard → chip;
               otherwise ResolveComponent.take_hit() → HURT / KILLED
       Enemy:  staggered + info.can_execute → execution (info.executed = true)
               otherwise HealthComponent.damage() + PostureComponent.add()
  → attacker gets hit_landed → reads info.executed / info.killed → Feel + rewards
```

### Player controller (`characters/player/player.gd`)

Movement style is ninja-like: a low leaning sprint (`run`, speed-matched via
`speed_scale`), a crouched half-walk `sneak` below `SNEAK_SPEED`, a forward-roll `dodge`, and
a front `flip` on double jumps (`FLIP_TIME`). The scarf ripples with follow-through (each
segment lags the previous one).

The hero is drawn with the Ronin sprite sheet (`tools/blender/models/ronin.py`, poses as
joint angles; see the docstring there for the angle conventions). `_animate()` picks the
animation from the state. Timed states set the frame from the state's progress, and slashes
map wind-up / strike / follow-through poses onto startup / active / recovery frames
(`_slash_frame()`), so the art always matches the frame data. After changing frame data or
poses, re-render and record the `combo` demo to check the strike pose lines up with hits.

**Combat choreography and effects (Dead Cells-style, keep them readable):**
- Each combo hit bursts forward when its active frames start (`slash_step_speed/frames`),
  the finisher leaps (`slash_hop`), and steps are pulled toward an enemy in front
  (`slash_magnet_*`, group `targets`). Air slashes pop up and slow the fall (hang time).
- The katana is long (`BLADE_LENGTH` in `ronin.py`, frames 160×120) and burns in every
  animation (`FireBlade`, fed from the same blade tracks as the trail). Flame particles use
  world coords, so a moving blade leaves fire behind; swings (intensity > 0.5) add swing fire
  that hangs in the air along the arc. Hits throw embers + `Feel.fire_burst`. The slash
  hitbox in `player.tscn` (60×36 at x 34) matches the blade's reach: change both together.
- `combo_hits` counts landed hits (resets after `combo_timeout` or when hurt) → HUD counter
  with ranks, and the trail's heat (red-orange → amber → white-hot).
- Every hit: `Feel.impact` (sparks, cut mark, light flash) + damage number. Executions add a
  short screen flash. Dodges, dashes, slams and big steps leave afterimages; jumps, landings
  and dodges kick up dust; slams make a shockwave ring; enemies die in a `death_burst`.
- Bloom: `rendering/viewport/hdr_2d` is on and the arena adds a WorldEnvironment glow with
  threshold 1.25, so only colors pushed above 1.0 glow (`Feel.GLOW`, `SwordTrail.EDGE_GLOW`).
  Keep glow, lights and flashes subtle: an earlier version washed out the whole screen.

States: `NORMAL` (run, jump, double jump, wall slide/jump, drop-through), `LEDGE`,
`DODGE` (i-frames), `SLASH` (3-hit 8-direction combo; also deflects projectiles),
`PARRY` (tap) → `GUARD` (hold), `DRAW_CHARGE` → `DRAW_STRIKE` (quick-draw: hold Slash
during the first hit, release to dash-strike), `SLAM` (Down + Slash in the air: dive, then a
landing shockwave), `CUT_LINK` (hold Interact next to a staggered Linked to free them),
`HURT`, `DEAD`. Focus (F) toggles solo slow
motion. Rewards: execution +1 Resolve, perfect parry +0.5 Resolve, Focus refills from
kills, parries and deflects.

### Enemies (`enemies/base/enemy_base.gd`)

Set `sprite_sheet` on the enemy scene to use an animated sprite (animations named like the
states, with aliases in `EnemyBase.ANIMATION_ALIASES`); without it the gray-box `Visual/Body`
polygon is used. Subclass `EnemyBase`, override `_ai(delta)` with `match state:` over StringName states,
switch with `set_state()`, call `telegraph()` during wind-ups and enable `attack_hitbox`
during attacks. The base owns `staggered`, `stunned` (after being parried), `dead`,
targeting (`target`, `distance_to_target()`), damage, execution and death. Give each
enemy an `EnemyData` `.tres` (wind-up ≥ 18 frames; a test enforces it), then give it a
letter in the map legend (`_spawn_entities()` in `test_arena.gd`) and place it in the map.

Hit reactions and deaths live in the base, tuned per enemy in `EnemyData` (group Reactions):
- Every hit: white flash, then an amber "burn" tint; the `Visual` node kicks back along the
  knockback, squashes, tilts and jitters (`REACT_*`, `_animate_reaction()`). The base owns
  `visual.position/scale/rotation`, so subclasses must not set them while alive.
- Flinch: a hit that doesn't kill or break posture puts the enemy in `&"hurt"` for
  `flinch_frames` (0 = never). Attacks are armored: no flinch while `is_armored()`
  (telegraphing or attack hitbox live) unless `flinch_during_attacks`. The rule is the pure
  `EnemyBase.should_flinch()` (unit tested).
- Death: `is_machine` enemies burst into scrap; a blade kill (`can_execute`) cuts the sprite
  in two along the swing (`CorpsePiece.slice`), anything else throws it whole, smoking.
  The pieces hold still for the hit freeze, then fly. People (`is_machine = false`, the
  Linked) fall away from the blow and fade: never cut them up.

### Art (PLAN.md section 30)

The art budget is $0: free tools + local AI image models + code. Image AI is only used for
still images (concepts, backgrounds, props, icons, illustrations). Animated characters and
enemies come from 3D (Mixamo/Blender) rendered to pixels, so frames stay consistent. Run every
image through `tools/art/pixelize.py` (game palette, pixel size). The palette is
`tools/art/palette.gpl`: use its color names in art scripts, never new colors. Code-made art
comes from `tools/art/generate_sandbox_art.py` (deterministic; outputs in `art/`). The tileset
layout is documented in that script and read by `game/arena/auto_tile.gd`: change both
together. Godot ignores `tools/` (it has a `.gdignore`). AI image prompts, seeds and the model
live in `tools/art/generate_ai_backgrounds.py`; raw outputs go to `tools/art/raw/` (not
committed). Backgrounds must stay darker than gameplay (see `BRIGHTNESS` in
`process_backgrounds.py`) so platforms and enemies stay readable. Log every AI asset in
`ASSET_LICENSES.md` (tool, model, prompt). Never put other games', studios' or artists' names
in prompts.

### Lighting

The world canvas has a dim, cool `CanvasModulate` (`TestArena.AMBIENT`), so light comes
from level lights, the hero's key light and the burning blade. 2D lights *multiply* the
color they hit, so on dark surfaces each `LevelLight` also paints a faint additive pool.
Characters have normal maps (`<name>_n.png`, rendered by Blender with a normal matcap;
boxes are beveled so edges catch light), applied by the sprite shader
(`SpriteSheet.material()`). Never wrap atlas frames in `CanvasTexture`: it ignores the
atlas region and shows the first frame forever (this bug froze the hero in idle once).
Lights need a `height` > 0 to shade normal-mapped sprites. Halos, pools and glowing
effects use unshaded additive materials.

### Sound (PLAN.md section 18)

Every sound is synthesized by `tools/audio/generate_audio.py` (whooshes, impacts, metal
partials, explosions, the "Neon Rain" music loop, a rain bed). To add one: write it in
`sfx()`, add its name to `Audio.SOUNDS`, regenerate, and call `Audio.play(&"name")` where it
happens. Every new action or enemy attack needs a sound: silent hits feel empty. Audio is
off in headless runs, so check sound with a `--write-movie` recording (it saves a .wav).

### Levels

Levels are multi-level (PLAN.md section 29.1): one-way platforms, drop-through floors,
wall-jump shafts, ledges and slam drops connect 3–5 stacked levels. Keep connectors within
the reach limits in that section (single jump ≤ 5 tiles up, double jump ≤ 8). The sandbox
map is plain text: change `game/arena/maps/sandbox.txt`, run the tests (the map test checks
borders, markers and footing), then check with `--overview` and a play.

## Tests

- Put tests in `tests/unit/test_<thing>.gd`, `extends TestCase`, methods named `test_...`.
- `before_each()` / `after_each()` for setup; free any Nodes you create.
- Assertions: `assert_true`, `assert_false`, `assert_eq` (same type required),
  `assert_near` (floats).
- Test pure logic directly (components, schemas, data rules). For behaviour that needs
  physics, use a demo scenario and check its event log.

## Current status (2026-10-26)

**M0 (setup):** done on the Mac. **M1 (combat feel, offline):** Ronin movement incl.
ledge grab; slash combo; parry/guard; deflect (perfect deflect returns to the shooter);
quick-draw; slam; executions; Focus slow-mo; Resolve pips; hit freeze, flash, shake.
Enemies: Hound (parry), Patrol Drone (deflect), Linked Citizen (cut the link; Mercy record in
`Profile.data["mercy"]`), training dummy. Multi-level sandbox map
(`game/arena/maps/sandbox.txt`) drawn with a code-generated tileset, a 3-layer AI-generated
parallax city backdrop and rain. Enemies flinch, recoil and burn on hits; machines are cut
in two by blade kills. Pixel-font HUD with no debug text. 53 unit tests; bot scenarios `combo`, `hound`, `drone`, `ledge`,
`slam`, `linked`, `ninja`, `brawl` all show the expected events.

Known limitations: Focus is solo-only (uses `Engine.time_scale`); ledges can only be
grabbed on `WORLD` geometry, not one-way platforms; enemies have no hurt pose of their own
(`hurt` reuses the stagger animation, or idle, plus the code recoil).

## Next tasks, in order (PLAN.md section 36)

Do these one at a time; each ends with passing tests and a demo log or recording.

1. **Smoother attack animations** (more in-between frames for the slashes), then the
   **demo build** (PLAN.md section 36: Warden boss, 2 areas, title/end screens, exports).
   Still open from kill feedback: pooling the effect particles and a kill freeze-frame
   (PLAN.md section 16).
2. **Touch controls v1** (PLAN.md section 15.4) as a `CanvasLayer` scene in `ui/touch/`
   that presses the same input actions (floating stick, Slash/Jump/Dodge/Parry/Focus).
3. **LAN co-op**: spawn one Player per peer with `MultiplayerSpawner`, sync with
   `MultiplayerSynchronizer`, set each player's authority to its peer id; host simulates
   enemies; test with Debug → Customize Run Instances (2 instances) plus lag simulation.
   Co-op Focus: slow only enemies near the user instead of `Engine.time_scale`.

Later milestones (blades data, level generator, run loop, EOS, art pipeline) are in
PLAN.md section 36.
