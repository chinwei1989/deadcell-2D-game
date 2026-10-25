# Implementation Plan: Original 3D Mobile Platformer (Unity, Windows)

> **Working title:** TBD · **Placeholder hero:** "Dash the Quokka"
> **Engine:** Unity 6 LTS (URP) · **Main dev machine:** Windows PC · **Platforms:** Android + iOS (Steam later)
> **Genre:** Full 3D platformer in the style of the classic Crash games: corridor levels, rail cameras, on-screen joystick

---

## Table of contents

1. [Vision and ground rules](#1-vision-and-ground-rules)
2. [Hardware, accounts and software](#2-hardware-accounts-and-software)
3. [Windows setup, step by step](#3-windows-setup-step-by-step)
4. [Building for iOS from a Windows workflow](#4-building-for-ios-from-a-windows-workflow)
5. [Working with Claude on Windows](#5-working-with-claude-on-windows)
6. [Repository and project structure](#6-repository-and-project-structure)
7. [Unity project settings](#7-unity-project-settings)
8. [Code architecture](#8-code-architecture)
9. [Gameplay design specification](#9-gameplay-design-specification)
10. [Touch controls specification](#10-touch-controls-specification)
11. [Camera system](#11-camera-system)
12. [Level design guidelines](#12-level-design-guidelines)
13. [Content plan (worlds and levels)](#13-content-plan-worlds-and-levels)
14. [Art direction and asset pipeline](#14-art-direction-and-asset-pipeline)
15. [Audio](#15-audio)
16. [UI and UX](#16-ui-and-ux)
17. [Save system](#17-save-system)
18. [Performance budgets](#18-performance-budgets)
19. [Monetization](#19-monetization)
20. [Analytics, crash reporting and privacy](#20-analytics-crash-reporting-and-privacy)
21. [Testing strategy](#21-testing-strategy)
22. [Milestones with task checklists](#22-milestones-with-task-checklists)
23. [Timeline](#23-timeline)
24. [Budget](#24-budget)
25. [Store release checklists](#25-store-release-checklists)
26. [Legal and IP](#26-legal-and-ip)
27. [Risks and mitigations](#27-risks-and-mitigations)
28. [After launch: updates and Steam port](#28-after-launch-updates-and-steam-port)
29. [Immediate next steps](#29-immediate-next-steps)

---

## 1. Vision and ground rules

**One-line pitch:** A bright, fast, crate-smashing 3D platformer built from the ground up
for phones. The feel of classic 90s mascot platformers, with controls that work under a thumb.

**Pillars**

| Pillar | Meaning |
|---|---|
| **Tight, forgiving controls** | Every jump feels fair on a touch screen. Players blame themselves, not the controls. |
| **Readable 3D** | Fixed rail cameras, drop shadows and clear warnings mean depth is never confusing. |
| **Smash everything** | Crates, chain reactions and collectibles reward exploring. |
| **Short, replayable levels** | 2–4 minute levels suit mobile sessions; gems and time trials bring players back. |

**Ground rules**

- 100% original character, name, world, art, music and story. **Nothing from Activision's
  Crash Bandicoot:** no names (Crash, Bandicoot, Wumpa, Aku Aku, Cortex), designs, music or logos.
- Gameplay *mechanics* (running, jumping, spinning, crates) are not protected and are fine to use.
- Test on a real phone from milestone 1 onward. The editor is not a phone.
- Gray-box first, art later. Never polish something that isn't fun yet.

---

## 2. Hardware, accounts and software

### 2.1 Hardware

| Item | Minimum | Recommended | Notes |
|---|---|---|---|
| Windows PC OS | Windows 10 (64-bit, recent version) | Windows 11 | Main development machine |
| Memory | 16 GB | 32 GB | Unity + IDE + browser use a lot |
| Storage | 100 GB free on an SSD | 250 GB+ on an NVMe SSD | Unity, modules, Library cache, builds |
| Graphics card | DirectX 11/12 GPU | Any GTX 1660 / RX 6600 class or better | Lightmap baking runs much faster on the GPU |
| Android test phone | Any Android 10+ phone | A cheap, low-end phone **plus** a mid-range phone | Low-end phones expose performance problems |
| Mac (for iOS) | Your Mac (M4 Pro) | — | Apple requires a Mac + Xcode to build and sign iOS apps |
| iPhone | Any iPhone that runs a current iOS | iPhone 12 or newer + one older model | For iOS testing |
| Bluetooth controller | Optional | Xbox or PlayStation controller | Tests controller support |

### 2.2 Accounts

| Account | Cost | When needed |
|---|---|---|
| Unity ID (Unity Personal license) | Free while revenue is under $200k/year | M0 |
| GitHub | Free (private repos included) | M0 |
| Google Play Console | $25 once | Before M10 (earlier for internal testing) |
| Apple Developer Program | $99/year | Before TestFlight (M9–M10). A free Apple ID is enough for testing on your own iPhone before that. |
| Unity Gaming Services (analytics, cloud save) | Free tier | M7 |

> **Personal vs organization store accounts:** Google Play *personal* accounts created after
> November 2023 must run a closed test with at least 12 testers for 14 days before going public.
> *Organization* accounts skip this but need a registered business and a D-U-N-S number
> (Apple also uses D-U-N-S for organizations). Decide this before M10.

### 2.3 Software (Windows)

| Software | Purpose | Cost |
|---|---|---|
| Unity Hub | Installs and manages Unity versions | Free |
| Unity 6 LTS (latest patch) | The engine | Free (Personal) |
| ↳ Android Build Support + OpenJDK + Android SDK & NDK Tools | Android builds | Free |
| ↳ iOS Build Support | Exports the Xcode project for iOS | Free |
| ↳ Windows Build Support (IL2CPP) | Future Steam build | Free |
| Visual Studio 2022 Community **or** VS Code + Unity extension | C# editor and debugger | Free (Visual Studio Community is free for individual commercial use) |
| Git for Windows + Git LFS | Version control for code and large art files | Free |
| GitHub Desktop (optional) | Visual Git client | Free |
| Blender | Editing and fixing 3D models | Free |
| Claude Code (desktop app or CLI) | AI pair-programmer | Your existing plan |
| Android device USB driver | Needed for some phones (e.g. Samsung USB driver) | Free |

---

## 3. Windows setup, step by step

### 3.1 Prepare Windows

1. Pick a **short** project path, for example `C:\Dev\DashGame`.
   Windows has a 260-character path limit, and Android (Gradle) builds can fail with long paths.
   Avoid OneDrive-synced folders such as Desktop and Documents, which slow Unity down and can corrupt the Library cache.
2. (Optional, recommended) Enable Windows long-path support. It's a Windows setting you change
   yourself in Group Policy or the registry.
3. Make sure at least 100 GB is free on the SSD.

### 3.2 Install the tools

1. Install **Git for Windows** (default options), then run:
   ```bash
   git lfs install
   ```
2. Install **Unity Hub** from unity.com and sign in with your Unity ID. Activate a **Personal** license.
3. In Unity Hub → *Installs* → *Install Editor* → choose the latest **Unity 6 LTS** and tick:
   - Android Build Support → **OpenJDK** and **Android SDK & NDK Tools**
   - iOS Build Support
   - Windows Build Support (IL2CPP)
   - Microsoft Visual Studio Community (if you choose Visual Studio)
4. If using Visual Studio, make sure the **"Game development with Unity"** workload is installed.
   For the future Steam IL2CPP build, also add **"Desktop development with C++"**.
5. Install **Blender**.
6. Install **Claude Code** on the PC (see [section 5](#5-working-with-claude-on-windows)).

### 3.3 Create the project

1. Unity Hub → *New project* → template **"Universal 3D"** (URP) → location `C:\Dev\DashGame`.
2. Create a private GitHub repository and connect it to the project (see [section 6](#6-repository-and-project-structure)).
3. Apply the project settings in [section 7](#7-unity-project-settings).
4. Install packages via *Window → Package Manager*:
   - Input System
   - Cinemachine (version 3.x)
   - Splines
   - ProBuilder (gray-box level building)
   - Addressables
   - Unity Test Framework (usually already included)
   - TextMeshPro / UI Toolkit (UI)
   - Later: In-App Purchasing, Analytics, Cloud Save, Mobile Notifications (optional)

### 3.4 First phone build (proves the setup works)

**Android**
1. On the phone: *Settings → About phone →* tap *Build number* 7 times → *Developer options →* enable **USB debugging**.
2. Plug the phone into the PC, accept the "Allow USB debugging" prompt, and install the vendor USB driver if Windows doesn't recognize the phone.
3. Unity → *File → Build Profiles →* Android → *Switch Platform →* select the phone under *Run Device →* **Build and Run**.
4. ✅ Done when the empty scene opens on the phone.

**iOS:** see [section 4](#4-building-for-ios-from-a-windows-workflow).

---

## 4. Building for iOS from a Windows workflow

Apple only allows iOS apps to be compiled and signed on a Mac with Xcode. You develop on
Windows and use your Mac only for iOS builds.

| Option | How it works | Pros | Cons |
|---|---|---|---|
| **A. Unity on the Mac** ⭐ (recommended) | Install Unity 6 (same version) + iOS Build Support on the Mac. `git pull` the repo there and build iOS directly. | Fewest surprises; plugins that use CocoaPods work automatically | Mac needs ~15 GB for Unity; free up disk space first (36 GB free now) |
| B. Export from Windows | On Windows, build target iOS → Unity writes an **Xcode project folder**. Copy it to the Mac (zip, network drive, or a git branch) → open in Xcode → sign → run. | No Unity install on the Mac | Manual copying each time; CocoaPods (`pod install`) must be run on the Mac for some plugins |
| C. Cloud build | Unity Build Automation or Codemagic builds iOS on their Macs from your GitHub repo. | Fully automatic; no Mac work | Usage costs after free tiers; signing setup is more complex |

**Recommended flow (Option A):**
1. Develop and test on Windows + Android every day.
2. About once a week, and before every beta: on the Mac → `git pull` → Unity → iOS → *Build* → open the Xcode project → set your Team under *Signing & Capabilities* → run on the iPhone.
3. For TestFlight and the App Store: in Xcode → *Product → Archive* → *Distribute App*.

**First iOS build (M0):**
1. Plug the iPhone into the Mac → on the iPhone, enable **Developer Mode** (Settings → Privacy & Security).
2. In Xcode → *Settings → Accounts* → add your Apple ID (free is fine for now).
3. Build from Unity → open `Unity-iPhone.xcodeproj` (or `.xcworkspace` if it exists) → choose your Team → Run.
4. On the iPhone: *Settings → General → VPN & Device Management* → trust your developer certificate.
5. ✅ Done when the empty scene opens on the iPhone.

---

## 5. Working with Claude on Windows

**Setup**
- Install Claude Code on the Windows PC (the Claude desktop app's Code tab, or the CLI). Git for Windows is required.
- Open the project folder (`C:\Dev\DashGame`) in Claude Code.
- This plan and a `CLAUDE.md` file (project conventions) live in the repo, so every session starts with the context.
  Memories saved on the Mac don't carry over to the PC; the repo does.

**Division of work**

| Claude | You |
|---|---|
| Writes all C# gameplay code, editor tools, shaders and build scripts | Installs software, signs in, creates accounts |
| Writes editor scripts that **generate gray-box levels** from layout data | Presses Play, tests on phones, reports how it *feels* |
| Explains and fixes errors from the Unity Console (paste them in or share screenshots) | Buys and commissions art, music and sound |
| Writes tests, store text, privacy policy draft, release checklists | Decorates and fine-tunes levels in the editor |
| Reviews performance profiler captures you share | Handles store submissions, signing and payments |

**Optional: Unity MCP.** Community and official MCP plugins for Unity let Claude read the
Console, inspect scenes and run editor actions directly. We'll evaluate one during M0. If it
works reliably it cuts down on copying and pasting errors.

**Daily loop**
1. Tell Claude the task (e.g. "add the TNT crate").
2. Claude writes or changes scripts and prefab-setup editor tools.
3. You switch to Unity → it recompiles → press Play → test.
4. Report results: errors, feel ("jump feels floaty"), or a screenshot.
5. Commit to Git once it works.

---

## 6. Repository and project structure

### 6.1 Git setup

- **`.gitignore`**: use GitHub's official Unity template. Never commit `Library/`, `Temp/`, `Obj/`, `Logs/`, `UserSettings/`, `Builds/`.
- **`.gitattributes`**: store large binaries with Git LFS:
  ```
  *.fbx *.blend *.psd *.png *.jpg *.tga *.exr *.wav *.mp3 *.ogg *.ttf *.otf *.mp4 *.asset filter=lfs diff=lfs merge=lfs -text
  ```
  (Exclude `.asset` from LFS if it's a text ScriptableObject; this is fine-tuned during M0.)
- Unity settings: *Edit → Project Settings → Editor →* **Asset Serialization: Force Text**, **Version Control: Visible Meta Files**.
- Branches: `main` (always builds) and short-lived `feature/*` branches.
- Commit after every working change. Tag milestones (`m1-graybox`, `m5-vertical-slice`, …).

### 6.2 Folder layout

```
DashGame/                       (repo root)
├── PLAN.md                     this document
├── CLAUDE.md                   coding conventions for Claude
├── ASSET_LICENSES.md           every bought or downloaded asset + its license
├── Assets/
│   ├── _Game/
│   │   ├── Scripts/
│   │   │   ├── Runtime/
│   │   │   │   ├── Core/         GameManager, events, service locator, scene loading
│   │   │   │   ├── Player/       controller, states, tuning, health, animation bridge
│   │   │   │   ├── Camera/       camera zones, rail/chase/side-scroll rigs
│   │   │   │   ├── Crates/       crate base class + every crate type
│   │   │   │   ├── Collectibles/ fruit, gems, extra lives
│   │   │   │   ├── Enemies/      enemy base, archetypes, bosses
│   │   │   │   ├── Hazards/      pits, spikes, platforms, boulder chase
│   │   │   │   ├── Level/        checkpoints, level flow, results, gem rules
│   │   │   │   ├── UI/           touch controls, HUD, menus, safe area
│   │   │   │   ├── Save/         save data, serialization, cloud sync
│   │   │   │   ├── Audio/        audio manager, music zones
│   │   │   │   └── Services/     IAP, analytics, achievements, haptics
│   │   │   ├── Editor/           level generator, validators, build menu
│   │   │   └── Tests/
│   │   │       ├── EditMode/
│   │   │       └── PlayMode/
│   │   ├── Prefabs/              Player, Crates, Enemies, Hazards, UI
│   │   ├── Config/               ScriptableObjects: PlayerTuning, LevelDefinitions…
│   │   ├── Scenes/
│   │   │   ├── Boot.unity
│   │   │   ├── MainMenu.unity
│   │   │   ├── Hub.unity
│   │   │   ├── GameplayCore.unity   player, camera rig, HUD (loaded additively)
│   │   │   └── Levels/W1_L1.unity …
│   │   ├── Art/                  Characters, Environments, VFX, Materials, Shaders
│   │   ├── Audio/                Music, SFX
│   │   └── UI/                   sprites, fonts
│   └── ThirdParty/               Asset Store packs (kept separate from your own files)
├── Packages/
└── ProjectSettings/
```

---

## 7. Unity project settings

| Setting | Value | Why |
|---|---|---|
| Render pipeline | URP, with a dedicated **Mobile** renderer asset | Fast on phones |
| Color space | Linear | Correct lighting |
| Active Input Handling | Input System Package (New) | On-screen controls + controllers |
| Scripting backend | IL2CPP | Required for iOS; faster on Android |
| Android architectures | **ARM64 only** | Google Play requires 64-bit |
| Android minimum API | Android 8.0 (API 26) to start; adjust later | Covers nearly all active phones |
| Android target API | Latest level Google Play requires | Store requirement |
| Android graphics APIs | Vulkan, with OpenGL ES 3 as a fallback | Performance + compatibility |
| 16 KB page size | Use a current Unity 6 LTS patch that supports it | Google Play requirement for new Android versions |
| iOS minimum version | iOS 15 (adjust later) | Broad coverage |
| Texture compression | ASTC | Best quality-to-size on modern phones |
| Orientation | Landscape Left + Landscape Right only | Platformer layout |
| Target frame rate | `Application.targetFrameRate = 60` (30 in battery-saver mode) | Mobile defaults to 30 otherwise |
| Incremental garbage collection | On | Fewer frame hitches |
| Managed stripping level | Medium | Smaller app |
| Asset serialization | Force Text | Git-friendly |
| Splash screen | Custom or disabled (optional on Unity 6 Personal) | Branding |
| Package name / bundle ID | `com.<yourstudio>.<gamename>` | Permanent; choose carefully |

---

## 8. Code architecture

### 8.1 Principles

- **Data-driven tuning:** all numbers (speeds, jump heights, timings) live in ScriptableObject
  assets, so you can tweak them in the editor without code changes.
- **Small components:** each behavior is its own script (e.g. `Breakable`, `Explosive`, `Bouncer`).
- **Events over hard links:** systems talk through C# events / a lightweight event bus
  (e.g. `CrateBroken`, `PlayerDied`, `CheckpointReached`), so the HUD and audio don't depend on gameplay classes.
- **Assembly definitions:** `Game.Runtime`, `Game.Editor`, `Game.Tests` for faster compiles.
- **Namespaces:** `DashGame.Player`, `DashGame.Crates`, etc.

### 8.2 Scene flow

```
Boot ──► loads save, initializes services (IAP, analytics, audio)
  └─► MainMenu ──► Hub (world map)
                    └─► GameplayCore (additive: Player, CameraRig, HUD, TouchControls)
                        + Level scene (additive: geometry, crates, enemies, camera zones)
                        └─► Results ──► back to Hub
```

Levels are **Addressables**, so later worlds can be downloaded after install to keep the app small.

### 8.3 Key classes

| Class | Responsibility |
|---|---|
| `GameManager` | Game state (Menu, Playing, Paused, Results), lives, current level |
| `LevelController` | Spawn point, checkpoints, crate total, gem rules, level timer, completion |
| `PlayerController` | Reads input, runs the movement state machine, moves the `CharacterController` |
| `PlayerTuning` (SO) | Every movement number (see 9.2) |
| `PlayerHealth` | Mask levels, invincibility frames, death, respawn |
| `PlayerAnimator` | Turns the movement state into Animator parameters |
| `CameraZone` | Trigger volume that activates a Cinemachine camera (rail / chase / side-scroll) |
| `Crate` (abstract) | Shared break logic, rewards, counts toward the level total |
| `EnemyBase` | Health, how it can be killed (jump / spin / both), contact damage |
| `BossController` | Phase-based state machine |
| `SaveService` | Load/save JSON, version migration, cloud sync |
| `InputRouter` | Combines touch, controller and keyboard into one action set |
| `HapticsService` | Short, light, heavy vibrations (iOS + Android) |

### 8.4 Player state machine

```
          ┌──────────┐  move input   ┌──────────┐
          │   Idle   │ ────────────► │   Run    │
          └────┬─────┘ ◄──────────── └────┬─────┘
     jump │    │ spin             spin │   │ jump / slide
          ▼    ▼                       ▼   ▼
     ┌────────┐  ┌────────┐       ┌────────┐ ┌────────┐
     │  Jump  │  │  Spin  │       │ Slide  │ │  Jump  │
     └───┬────┘  └────────┘       └───┬────┘ └────────┘
 apex/   │  spin in air ──► AirSpin    │ jump ──► LongJump
 release ▼                             ▼
     ┌────────┐  slam  ┌──────────┐
     │  Fall  │ ─────► │ BodySlam │
     └───┬────┘        └──────────┘
   land  ▼
     (Idle/Run)     Any state ──hit──► Hurt ──► (Idle) or Dead ──► Respawn
```

---

## 9. Gameplay design specification

### 9.1 Moveset

| Move | Input | Behavior |
|---|---|---|
| Run | Joystick | Analog speed; quick acceleration and stopping |
| Jump | Tap JUMP | Short hop on tap, full jump on hold (variable height) |
| Spin | Tap SPIN | 0.45 s spin: breaks crates, kills spin-vulnerable enemies, deflects some projectiles |
| Air spin | SPIN in the air | Slightly slows falling once per jump (helps fix bad jumps) |
| Slide | SLIDE while running | Low, fast dash under obstacles |
| Long jump | JUMP during a slide | Long, low jump |
| Body slam | SLIDE in the air | Drops straight down: breaks iron-reinforced crates, stuns ground enemies |
| Bounce | Land on an enemy / bounce crate | Auto-bounce; holding JUMP bounces higher |

### 9.2 Starting tuning values (all editable in `PlayerTuning`)

| Parameter | Start value | Notes |
|---|---|---|
| Max run speed | 7.5 m/s | |
| Acceleration / deceleration | 60 / 80 m/s² | Snappy, not icy |
| Air control | 65% of ground acceleration | |
| Jump height (tap / hold) | 1.3 m / 2.4 m | |
| Gravity going up / coming down | 30 / 55 m/s² | Faster falls feel tighter |
| Terminal fall speed | 22 m/s | |
| Coyote time | 0.12 s | Jump allowed just after leaving a ledge |
| Jump buffer | 0.15 s | Early taps before landing still count |
| Spin duration / cooldown | 0.45 s / 0.20 s | |
| Spin radius | 1.1 m | |
| Spin auto-aim | Within 2.5 m, 60° cone | Gently turns toward the nearest enemy |
| Slide duration / speed | 0.5 s / 11 m/s | |
| Invincibility after a hit | 1.5 s | Flashing hero |
| Ledge assist | Snap up if within 0.25 m of a ledge top | Forgives near misses |

### 9.3 Crates

| Crate | Behavior | Counts toward gem? |
|---|---|---|
| **Wooden** | Breaks on jump/spin; drops 1–5 fruit | ✅ |
| **Bounce** | Bounces the player; breaks after 5 bounces (gives fruit each time) | ✅ |
| **Question (?)** | Random: fruit, extra life or mask | ✅ |
| **Life** | Extra life | ✅ |
| **Mask** | Mask power-up | ✅ |
| **Checkpoint** | Saves respawn position (and broken crates so far) | ✅ |
| **Spring** | Unbreakable launch pad (iron) | ❌ |
| **Iron** | Unbreakable; used as a platform; body slam on reinforced variant | ❌ / ✅ (reinforced) |
| **TNT** | Jump on it: 3-second fuse. Spin: explodes at once (hurts player). Chain reacts. | ✅ |
| **Nitro** | Explodes on any touch; hops when the player is near. Cleared by the level's switch crate. | ✅ |
| **Switch (!)** | Turns outline crates solid, or blows up all Nitros | ✅ |
| **Outline** | Ghost crates that become solid after the switch | ✅ |

- Explosions use a radius (2.2 m) and chain to nearby TNT/Nitro with a 0.1 s delay per link (looks great).
- The crate counter shows `broken / total`. Breaking every crate in a level awards the **level gem**.
- Crates broken before a checkpoint stay broken after respawn.

### 9.4 Health and the mask

| Masks held | Effect |
|---|---|
| 0 | One hit = death |
| 1 | Absorbs one hit |
| 2 | Absorbs two hits; mask glows |
| 3 | 8 seconds of invincibility (touching enemies destroys them, fast music), then back to 2 |

Some deaths ignore masks: falling into pits, water, being crushed, and boulders.

### 9.5 Lives and fruit

- Start with 4 lives. 100 fruit = extra life. Game over → restart the level from the start with 4 lives (no harsh punishment).
- **Assist option:** infinite lives (on by default for an easier difficulty setting; doesn't affect gems).
- **Fair-play rule:** after 5 deaths at the same checkpoint, offer a free mask on respawn.

### 9.6 Collectibles and completion

| Item | How to get it | Reward |
|---|---|---|
| Fruit | Everywhere, crates | Extra lives |
| Level gem | Break every crate in a level | Completion %, unlocks bonus content |
| Hidden gem | Secret route or challenge in some levels | Unlocks secret levels |
| Time trial medals (gold/silver/bronze) | Beat target times after first clearing a level | Completion %, cosmetic skins |
| Keys (bonus rounds) | Optional bonus areas | Unlock a secret world |

### 9.7 Enemies

| Archetype | Behavior | Kill by |
|---|---|---|
| Patroller (e.g. crab) | Walks a fixed path | Jump or spin |
| Spiky (e.g. hedgehog) | Spikes on top | Spin only |
| Shield (e.g. turtle) | Front shield | Jump only (spin bounces off) |
| Charger (e.g. boar) | Charges when the player is in line | Dodge, then spin from the side |
| Hopper (e.g. frog) | Jumps toward the player in bursts | Jump or spin |
| Flyer (e.g. bat, bird) | Swoops on a path | Spin (or jump with good timing) |
| Shooter (e.g. tiki plant) | Spits projectiles on a rhythm | Spin (deflects projectiles) |
| Chomper plant | Stationary, lunges | Spin when it's open |

Every enemy has a clear **warning** before it attacks (wind-up animation + sound).

### 9.8 Hazards

Bottomless pits · spikes (pop-up on a rhythm) · rolling logs · fire jets · crushing pistons · swinging blades/logs ·
crumbling platforms (0.6 s shake then fall) · moving platforms (the player moves with them) · water/lava ·
**boulder chase** (scripted runs toward the camera) · electric fences on timers.

### 9.9 Bosses (one per world)

- 3 phases, each with a readable attack pattern and a clear "hit me now" window.
- The player wins with the normal moveset (jump on the boss, spin projectiles back, use the arena's TNT).
- Checkpoint between phases on easy difficulty.

---

## 10. Touch controls specification

```
┌───────────────────────────────────────────────────────────┐
│ ♥ x4   🍎 42   📦 12/40   ⏱ 1:23                     ⏸    │
│                                                           │
│                                                           │
│                                                  ┌──────┐ │
│                                                  │ SPIN │ │
│      ╭─────╮                                     └──────┘ │
│      │  ◯  │  ← floating joystick         ┌──────┐┌──────┐│
│      ╰─────╯    (appears where you touch) │SLIDE ││ JUMP ││
│                                           └──────┘└──────┘│
└───────────────────────────────────────────────────────────┘
```

| Element | Spec |
|---|---|
| Joystick zone | Left 45% of the screen. The stick appears where the thumb lands. |
| Joystick | 140 px radius base (scales with screen DPI), 12% dead zone, smooth response curve |
| Buttons | 110–130 px diameter, ≥ 24 px apart; JUMP is the largest |
| Hold detection | JUMP held → higher jump; SPIN hold does nothing (avoids accidental spins) |
| Multi-touch | Joystick + any button at once; sliding a thumb from JUMP to SPIN triggers SPIN |
| Feedback | Button press animation + light vibration; heavy vibration on hurt |
| Safe area | All UI respects notches and rounded corners (`Screen.safeArea`) |
| Customization | Settings → *Edit controls*: drag to move, slider to resize, opacity 30–100%, left-handed swap |
| Controllers | Bluetooth Xbox/PlayStation/MFi controllers auto-detected; touch UI hides |
| Accessibility | Optional "hold to run" auto-run toggle, larger buttons preset, reduced camera shake |

---

## 11. Camera system

Built with **Cinemachine 3** + **Splines**. The player never controls the camera.

| Camera type | Used for | How it works |
|---|---|---|
| **Rail (behind)** | Main "into the screen" levels | Camera rides a spline above and behind the path, keeping the player at a set distance |
| **Chase (front)** | Boulder/creature chases toward the camera | Camera rides ahead of the player looking back; the hazard is visible behind them |
| **Side-scroll (2.5D)** | Side-view platforming sections | Camera on a parallel spline; the player moves left/right on a locked depth |
| **Arena** | Bosses | Fixed or slowly orbiting framing of the whole arena |
| **Cinematic** | Level intro, gem reveals | Short Timeline sequences |

**Rules**
- **`CameraZone`** trigger volumes switch cameras with a 0.6–1.0 s blend.
- Look slightly ahead of the player's movement direction.
- Pull back during big jumps; push in slightly in tight spaces.
- Drop shadow under the hero is always on (a projected blob or decal) so landing spots are clear.
- Small dotted landing marker for very long jumps (optional, on easy difficulty).

---

## 12. Level design guidelines

**Size and pacing**
- 2–4 minutes for a first clear. 40–90 crates. 2–3 checkpoints (≤ 45 s of replay after any death).
- Structure: **introduce** a mechanic safely → **develop** it → **twist** it → **finale** → exit.
- A new mechanic in each level, or a new combination of old ones.

**Distances for touch (player at 7.5 m/s)**

| Metric | Value |
|---|---|
| Max gap with a full jump | 4.5 m (design max: 3.8 m, leaves room for error) |
| Max height with a full jump | 2.4 m (design max: 2.0 m) |
| Minimum platform width | 1.6 m (2.0 m in early levels) |
| Minimum moving-platform size | 2.2 × 2.2 m |
| Crate size | 1 × 1 × 1 m (the base grid unit) |

**Rules**
- Never hide hazards from the camera; warn before every danger.
- Fruit lines show where to go and where to jump.
- Secret paths are hinted at (a cracked wall, a lone crate).
- Crates the player needs for the gem should be reachable on the main path or clearly marked side paths.
- Test every level on a real phone *before* adding final art.

**Workflow**
1. Paper or whiteboard sketch.
2. Gray-box with **ProBuilder** + prefab crates/enemies (or Claude's editor generator from a layout file).
3. Phone test → tune.
4. Art pass: replace boxes with environment art.
5. Light bake, performance check, final polish.

**Level validator (editor tool):** checks every level for missing checkpoints, unreachable
crates, missing kill volumes under gaps, the crate total, and missing camera zones.

---

## 13. Content plan (worlds and levels)

**Launch scope: 3 worlds × 5 levels + 1 boss each = 15 levels + 3 bosses** (+ 3 secret levels).

| World | Theme | Level types | Signature mechanic | Boss |
|---|---|---|---|---|
| **1. Sunny Isles** | Tropical beach and jungle | Into-the-screen, 1 side-scroll, 1 boulder chase | Basics, bounce crates, TNT | Giant crab chieftain |
| **2. Lost Temple** | Ancient ruins, caves | Into-the-screen, dark torch level, rope bridges | Crumbling platforms, spike traps, Nitro + switch | Stone guardian |
| **3. Steamworks** | Industrial factory and volcano | Side-scroll, conveyor belts, rising lava chase | Pistons, conveyors, electric timers | The villain's mech |

**Hub:** an island map. Each world's levels open in order, with the boss gate needing 5 levels cleared.

**Story (light):** the villain is stealing the island's "sun stones"; the hero chases them
through each world. Told with short, skippable scenes with no voice acting.

**Vertical slice level (M5):** World 1, Level 2: the jungle path (rail camera, all basic
crates, 3 enemy types, 1 short boulder chase, 2 checkpoints).

---

## 14. Art direction and asset pipeline

### 14.1 Style

- **Stylized, bright, cartoony:** saturated colors, chunky shapes, readable silhouettes.
  This looks great on phones and runs fast.
- Toon shading with a soft rim light; baked lighting with light probes for moving objects.
- Hero: an expressive original animal mascot with oversized hands, feet and eyes, and a bold color that stands out from every environment.

### 14.2 Style guide (create in M0–M1)

- Color palette per world, a hero turnaround (front/side/back), a size chart (hero vs crates vs enemies),
  a shape language (rounded = friendly, spiky = danger), and the UI color/typography.

### 14.3 Asset sources

| Asset | Prototype (M1–M4) | Final (M5+) |
|---|---|---|
| Hero | Capsule → a Mixamo character | **Commissioned original** concept → model → rig → animations |
| Hero animations | Mixamo (free, commercial use allowed) | Custom: idle, run, jump, fall, land, spin, slide, slam, hurt, death ×3, victory dance |
| Environments | ProBuilder gray-box | Stylized Asset Store packs (customized: recolored, mixed) + custom hero pieces |
| Enemies | Primitives | Asset Store creatures restyled, or commissions |
| VFX | Basic particles | Stylized VFX packs: crate splinters, fruit sparkle, explosions, dust |
| UI | Placeholder | Custom icons, logo, fonts (check font licenses) |

### 14.4 Technical art rules

| Item | Budget |
|---|---|
| Hero | 8–15k triangles, 1 material, 1024² texture, ≤ 60 bones |
| Enemies | 2–6k triangles, 512² textures |
| Crates | ≤ 300 triangles, shared atlas |
| Environment | Texture atlases (1024²–2048² per world); reuse modular pieces |
| LODs | 2–3 levels for anything large or repeated |
| Import | FBX from Blender, scale 1 unit = 1 m, Y-up handled at export |
| Textures | ASTC compression, mipmaps on, max 1024 on low-quality tier |

### 14.5 Commissioning the hero

1. Write a one-page brief: personality, size, reference board (*inspired by, not copied from*).
2. Concept artist: 3–5 rough options → pick one → refine → turnaround sheet.
3. 3D artist: model + textures + rig (Humanoid or Generic) + facial blend shapes (optional).
4. Animator (or same artist): the animation list above.
5. **Get a written contract that transfers full commercial rights to you.**

---

## 15. Audio

| Area | Plan |
|---|---|
| Music | One upbeat theme per world + boss, menu, hub, invincibility, results. Loops of 1.5–3 minutes. Commission a composer or license royalty-free tracks with commercial rights. |
| SFX | Jump, land, spin, slide, crate break (wood/iron), fruit pickup (pitch rises with combos), TNT fuse ticks, explosion, hurt, death, checkpoint, gem, menu clicks |
| Mixing | Unity Audio Mixer groups: Music, SFX, UI, Ambience. Separate volume sliders in Settings. |
| Format | Vorbis/AAC compressed; short SFX loaded into memory, music streamed |
| Audio zones | Ambience changes per area (jungle birds, cave drips) |
| Haptics sync | Strong haptics on explosions and bosses, light on pickups (toggle in Settings) |

---

## 16. UI and UX

**Screens:** Splash → Title → Main menu (Play, Settings, Credits) → Hub map → Level intro card →
HUD → Pause (Resume, Restart, Settings, Quit) → Death / Game over → Results (time, crates, gems,
medals) → Shop (full unlock, skins) → Settings.

**Settings:** music/SFX volume · haptics on/off · edit controls · graphics quality (Low/Medium/High/Auto)
· 30/60 fps · language · difficulty/assist (infinite lives, landing marker) · reduced camera shake ·
restore purchases · privacy/consent · credits.

**HUD rules:** top bar only; fades out during play and reappears when values change; never overlaps the touch controls.

**First-time experience:** a playable tutorial woven into W1-L1 (move → jump → spin → crate → enemy), no text walls; the first 60 seconds must be fun.

**Localization (M7):** English first; prepare Unity Localization tables from the start
(no hard-coded text). Candidate languages: Spanish, Portuguese (BR), French, German, Japanese,
Korean, Chinese (Simplified), Indonesian, Malay.

**Screen support:** 16:9 to 21:9 phones and 4:3 iPads. Test on both extremes.

---

## 17. Save system

- **Local:** JSON file in `Application.persistentDataPath`, written atomically (write a temp file, then rename) with one backup copy.
- **Cloud:** Unity Gaming Services Cloud Save, linked to Apple / Google sign-in so progress moves to a new phone.
- **Versioning:** `saveVersion` field with migrations so updates never wipe progress.
- **When to save:** level complete, checkpoint, purchase, settings change, and when the app is paused or closed.

```json
{
  "saveVersion": 1,
  "lives": 4,
  "fruit": 37,
  "unlockedWorlds": [1, 2],
  "levels": {
    "W1_L1": { "cleared": true, "gem": true, "hiddenGem": false, "bestTime": 102.4, "medal": "silver" }
  },
  "purchases": { "fullGame": false, "skins": ["default"] },
  "settings": { "music": 0.8, "sfx": 1.0, "haptics": true, "quality": "auto", "controlsLayout": {} },
  "stats": { "deaths": 51, "cratesBroken": 1203, "playTimeSec": 5400 }
}
```

---

## 18. Performance budgets

**Target devices**

| Tier | Example class | Target |
|---|---|---|
| Low | ~4 GB RAM Android phones, iPhone XR/11 class | 30 fps, Low quality |
| Mid | Galaxy A5x class, iPhone 12–13 | **60 fps**, Medium quality |
| High | Recent flagships, iPhone 15+ | 60 fps (120 Hz optional), High quality |

**Per-frame budget (mid tier, 16.6 ms)**

| Item | Budget |
|---|---|
| Visible triangles | ≤ 200k |
| SetPass calls | ≤ 60 (SRP Batcher + GPU instancing + atlases) |
| Draw calls | ≤ 150 |
| Realtime lights | 1 directional; everything else baked |
| Shadows | Blob/decal shadow for hero and enemies; realtime shadows on High tier only |
| Post-processing | Color grading (LUT) + light bloom on Medium/High; none on Low |
| Transparent overdraw | Limit particle sizes; no big transparent planes |
| Scripts | No allocations in `Update`; object pooling for fruit, VFX, projectiles |
| Memory | ≤ 1.2 GB on low tier |
| App download | Base install ≤ 150 MB; later worlds as downloadable asset packs |

**Tools:** Unity Profiler (connected to the phone over USB), Frame Debugger, Memory Profiler,
Android GPU Inspector / Xcode GPU tools. Check performance at the end of **every** milestone, not just at M9.

**Quality tiers:** Auto-detect on first launch from device memory and GPU, with manual override in Settings.
Render scale: Low 0.75, Medium 0.9, High 1.0.

---

## 19. Monetization

**Recommended: "Free to start, buy once."**

| Item | Price (suggested) | Type |
|---|---|---|
| World 1 (5 levels + boss) | Free | — |
| **Full game unlock** (Worlds 2–3 + secret levels) | $4.99–$6.99 | Non-consumable IAP |
| Cosmetic hero skins | $0.99–$1.99 each, or earned via medals | Non-consumable IAP |
| Future world expansion | $1.99–$2.99 | Non-consumable IAP |

**Why:** platformer fans dislike energy timers and forced ads. "Free to try" lets people
discover the game, and a one-time unlock earns trust and good reviews.

**Not included:** energy systems, loot boxes, pay-to-win, forced ads.
(Optional later: rewarded ads, e.g. "watch an ad for a free mask", only if numbers support it.
These need an ad SDK, a consent prompt, and on iOS possibly App Tracking Transparency.)

**Implementation:** Unity In-App Purchasing package, product IDs defined in both stores,
**Restore Purchases** button (required by Apple), receipt validation, and sandbox testing on both stores.

---

## 20. Analytics, crash reporting and privacy

| Need | Tool |
|---|---|
| Crash and error reports | Unity Cloud Diagnostics or Firebase Crashlytics |
| Gameplay analytics | Unity Analytics (UGS) |
| Key events | `level_start`, `level_complete` (time, deaths), `player_death` (level, position, cause), `checkpoint`, `purchase`, `tutorial_step` |
| Death heatmaps | Death positions per level → find unfair spots to fix |

**Privacy**
- Collect only what's needed; no personal data in events.
- Consent prompt where required (e.g. EU/UK) before analytics.
- Write a **privacy policy** (hosted on a simple website, e.g. GitHub Pages) and fill in Apple's
  *App Privacy* labels and Google's *Data safety* form to match the SDKs actually used.
- Without ads or cross-app tracking, Apple's tracking (ATT) prompt isn't needed.

---

## 21. Testing strategy

| Type | What | When |
|---|---|---|
| Edit mode tests | Save serialization and migration, crate counting, fruit → life math, IAP unlock logic | Every change (run from the Test Runner) |
| Play mode tests | Jump reaches the tuned height ±5%, coyote time works, TNT chain timing, checkpoint restore | Every milestone |
| Level validator | Automatic checks per level (see section 12) | Before committing a level |
| Device testing | Weekly build on low-end Android + iPhone | From M1 |
| Feel testing | Watch 3–5 people play without helping; note where they die and get confused | M2, M5, M6, M9 |
| Closed beta | Google Play closed test (12+ testers, 14+ days) + TestFlight | M9–M10 |
| Store compliance | Purchases, restore, privacy, age ratings, offline play | M10 |

**Optional automation (M9):** GitHub Actions + GameCI to build Android automatically on each push to `main`.

**Bug tracking:** GitHub Issues with labels `bug`, `feel`, `perf`, `art`, `level:W1_L2`.

---

## 22. Milestones with task checklists

### M0 — Setup and pre-production · ~1–2 weeks

**Setup**
- [ ] Windows PC prepared (short project path, 100 GB+ free)
- [ ] Git + Git LFS, Unity Hub, Unity 6 LTS + Android/iOS/Windows modules, IDE installed
- [ ] Claude Code installed on the PC
- [ ] URP project created; packages installed; settings from section 7 applied
- [ ] GitHub private repo with `.gitignore`, `.gitattributes`, `PLAN.md`, `CLAUDE.md`, `ASSET_LICENSES.md`
- [ ] Empty build running on an Android phone
- [ ] Unity installed on the Mac; empty build running on an iPhone
- [ ] (Optional) Unity MCP plugin evaluated

**Pre-production**
- [ ] Hero name + game title chosen; quick trademark search done (USPTO, WIPO, app stores)
- [ ] One-page game design summary (pitch, pillars, moveset, worlds)
- [ ] Reference board + first style guide draft
- [ ] Package name / bundle ID chosen

**✅ Exit:** an empty app runs on both phones from the same repo.

### M1 — Gray-box movement · ~2–3 weeks

- [ ] `PlayerTuning` ScriptableObject + `PlayerController` (run, jump, fall, gravity, coyote time, jump buffer)
- [ ] `InputRouter` with on-screen joystick + JUMP button; keyboard/controller for editor testing
- [ ] Blob shadow under the player
- [ ] Rail camera on a spline + `CameraZone` switching
- [ ] Test level: straight path, gaps, steps, a turn, a moving platform
- [ ] Kill volumes + respawn at the start
- [ ] Safe area handling for the UI
- [ ] Weekly phone builds; first tuning pass on the phone

**✅ Exit:** running and jumping feels good on a real phone. Five friends can cross the test level without complaining about controls.

### M2 — Full moveset and feel · ~2–3 weeks

- [ ] Spin (with auto-aim), air spin, slide, long jump, body slam, bounce
- [ ] Ledge assist
- [ ] Player state machine finished + Mixamo placeholder character and animations
- [ ] Haptics service
- [ ] SPIN and SLIDE buttons; control customization screen (move, resize, opacity, left-handed)
- [ ] Bluetooth controller support
- [ ] "Juice": landing squash, dust particles, speed lines, camera shake (with a reduce option)

**✅ Exit:** just moving around is fun. A feel test with 3–5 people passes.

### M3 — Crates and collectibles · ~2 weeks

- [ ] `Crate` base + all crate types from section 9.3
- [ ] Explosion system with chain reactions
- [ ] Fruit (pooled), extra lives, mask power-up (0–3 levels + invincibility)
- [ ] Checkpoints (restore position + keep broken crates)
- [ ] HUD: lives, fruit, crate counter, timer
- [ ] Gem awarded for breaking all crates; results screen v1
- [ ] Edit mode tests for crate counting and fruit → life

**✅ Exit:** every crate type works in a test room, and the gem can be earned.

### M4 — Enemies, hazards and the first boss · ~3–4 weeks

- [ ] `EnemyBase` + 6 archetypes from section 9.7 (gray-box models)
- [ ] Hazards: spikes, rolling logs, fire jets, crumbling platforms, moving platforms, water
- [ ] Boulder chase: front-facing chase camera + scripted boulder on a spline
- [ ] Side-scroll camera section
- [ ] First boss (gray-box) with 3 phases
- [ ] `LevelController` + level validator editor tool
- [ ] Full gray-box version of the vertical slice level (W1-L2) + boss arena

**✅ Exit:** a complete gray-box level and boss are playable start to finish on a phone.

### M5 — Vertical slice · ~4–8 weeks · ⭐ decision point

- [ ] Hero concept finished and commissioned; final model, rig and core animations delivered
- [ ] World 1 environment art (Asset Store packs + customization)
- [ ] Final crates, fruit, VFX, 3 enemy models
- [ ] Toon shading, baked lighting, light probes, post-processing per tier
- [ ] World 1 music + all core SFX
- [ ] Main menu, pause, settings, results with final UI art
- [ ] 60 fps on a mid-tier phone, 30 fps on a low-tier phone
- [ ] 60–90 s gameplay trailer recorded from the slice

**✅ Exit / decision:** the slice looks and plays like a real game. Show it to 10+ people (and
optionally post short clips on social media). **Decide:** continue as planned, adjust the art
style or scope, or cut back the content.

### M6 — Content production · ~3–6 months

- [ ] World 1: 5 levels + boss (final art)
- [ ] World 2: 5 levels + boss
- [ ] World 3: 5 levels + boss
- [ ] 3 secret levels + bonus rounds
- [ ] Hidden gems and time trial targets per level
- [ ] Short story scenes (Timeline)
- [ ] Each level: sketch → gray-box → phone test → art → bake → perf check → validator pass

**✅ Exit:** all levels finished and playable from start to end.

### M7 — Game systems · ~3–4 weeks (alongside M6)

- [ ] Hub/world map with unlock rules
- [ ] Save system + migrations + cloud save
- [ ] Time trials + medals; cosmetic skins
- [ ] Achievements: Google Play Games Services + Apple Game Center
- [ ] Localization tables + first translations
- [ ] Assist options (infinite lives, landing marker, larger buttons)
- [ ] Credits screen

**✅ Exit:** the full loop works: new game → all worlds → 100% completion, with progress carried to a second phone.

### M8 — Monetization · ~2 weeks

- [ ] Products created in Play Console and App Store Connect
- [ ] Unity IAP: full-game unlock, skins, restore purchases
- [ ] World 2+ gate + shop screen (clear, friendly, no dark patterns)
- [ ] Sandbox purchases tested on both platforms (buy, restore, reinstall, offline)

**✅ Exit:** purchases work in both store sandboxes.

### M9 — Performance, polish and beta · ~3–4 weeks

- [ ] Profile every level on low/mid/high devices; fix hotspots
- [ ] Quality auto-detect; 30/60 fps toggle; battery and heat checks (30-minute play sessions)
- [ ] App size: base ≤ 150 MB; Addressables / Play Asset Delivery for later worlds
- [ ] Analytics + crash reporting live; consent flow
- [ ] Death heatmap review → difficulty fixes
- [ ] Google Play internal test → **closed test with 12+ testers for 14+ days**
- [ ] TestFlight beta on iOS
- [ ] Bug bash: fix all crash and blocker bugs

**✅ Exit:** no known crashes, stable frame rate on target devices, positive beta feedback.

### M10 — Store release · ~3–4 weeks

- [ ] Store assets: icon, screenshots, feature graphic, trailer, descriptions (see section 25)
- [ ] Privacy policy published; Data safety + App Privacy forms done
- [ ] Age ratings (IARC questionnaire for Google; Apple's age rating questions)
- [ ] Release builds signed (Play App Signing; Apple distribution certificate)
- [ ] Submit for review on both stores; respond to any rejections
- [ ] Launch day: social posts, press kit, small-creator outreach

**✅ Exit:** live on Google Play and the App Store. 🎉

---

## 23. Timeline

Assuming you work on it most days, with Claude writing the code:

```
Month:   1    2    3    4    5    6    7    8    9    10   11   12   13
M0      ██
M1       ██
M2        ███
M3           ██
M4            ████
M5                ████████
M6                        ████████████████████████
M7                                  ██████
M8                                          ██
M9                                            ████
M10                                               ████
```

**Total: about 9–14 months to launch.** Art delivery (especially the hero) is the most likely
cause of delays, so **commission the hero during M2–M3** so it arrives for M5.

---

## 24. Budget

| Item | Low | High |
|---|---|---|
| Google Play developer account | $25 | $25 |
| Apple Developer Program (year 1) | $99 | $99 |
| Hero concept + model + rig + animations | $1,000 | $5,000 |
| Environment packs (3 worlds) | $100 | $500 |
| Enemies + bosses (packs or commissions) | $150 | $2,000 |
| VFX + UI packs | $50 | $200 |
| Music (licensed or commissioned) | $300 | $3,000 |
| SFX packs | $30 | $150 |
| Test phones (one low-end Android) | $120 | $300 |
| Logo / store art | $0 (DIY) | $500 |
| Trademark search/filing (optional) | $0 | $1,000 |
| **Total** | **~$1,900** | **~$12,800** |

Unity Personal, Git, GitHub, Blender and Visual Studio Community are free.

---

## 25. Store release checklists

### 25.1 Google Play

- [ ] Developer account created and identity verified
- [ ] App created in Play Console; package name matches the build
- [ ] **Android App Bundle (.aab)** built with IL2CPP, ARM64, targeting the required API level
- [ ] Play App Signing enabled; upload key stored safely (back it up! Losing it is painful)
- [ ] Store listing: title (≤ 30 characters), short description (≤ 80), full description (≤ 4,000)
- [ ] Graphics: icon 512×512, feature graphic 1024×500, at least 4 landscape phone screenshots, 7"/10" tablet screenshots, optional YouTube trailer
- [ ] Content rating (IARC questionnaire)
- [ ] Data safety form; privacy policy URL
- [ ] Target audience (choose ages carefully: "under 13" adds extra family-policy rules)
- [ ] In-app products created and activated
- [ ] Internal test → **closed test (12+ testers, 14+ continuous days)** for personal accounts
- [ ] Apply for production access → production release (staged rollout: 20% → 50% → 100%)

### 25.2 Apple App Store

- [ ] Apple Developer Program membership active
- [ ] Bundle ID registered; app record created in App Store Connect
- [ ] Built with the Xcode/SDK version Apple currently requires
- [ ] Signing: Xcode automatic signing with your distribution certificate
- [ ] TestFlight internal → external beta (external requires a short beta review)
- [ ] App Privacy details ("nutrition labels")
- [ ] Age rating questionnaire
- [ ] Screenshots: 6.9" (or 6.5") iPhone landscape; 13" iPad if iPad is supported
- [ ] App preview video (optional, up to 30 s)
- [ ] In-app purchases created, with review screenshots; Restore Purchases works
- [ ] Encryption export compliance (standard HTTPS only → exempt)
- [ ] Review notes: explain the free World 1 + unlock model
- [ ] Submit; plan for 1–2 days of review and a possible rejection round

---

## 26. Legal and IP

- **Originality:** no names, designs, music, logos or story from Crash Bandicoot or other games.
  Mechanics are fine; "inspired by 90s mascot platformers" is fine in marketing; naming Crash in store text is not.
- **Name check:** search app stores, Steam, USPTO and WIPO for the title and hero name before committing. Consider registering the trademark once the vertical slice is done.
- **Asset licenses:** record every asset in `ASSET_LICENSES.md` (source, license, date, receipt).
  Unity Asset Store and Mixamo assets are allowed in commercial games, but not for redistribution as raw files.
- **Commissions:** written contracts transferring full commercial rights (or an exclusive, perpetual, worldwide license) to you.
- **Fonts and music:** confirm commercial and app embedding rights.
- **AI-generated assets:** if used, record which ones. Steam requires disclosing them.
- **Business:** consider a simple business registration (sole proprietor or company) before launch, for store organization accounts, tax and payouts. Fill in the store tax forms.

---

## 27. Risks and mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Touch controls feel bad | Medium | High | Phone testing from M1, forgiveness systems, customizable layout, controller support |
| Scope grows too big | High | High | Fixed launch scope (15 levels), M5 decision point, cut list ready (e.g. secret world) |
| Hero art late or poor | Medium | High | Commission early (M2–M3), milestone payments, a backup option from the Asset Store |
| Performance on low-end phones | Medium | Medium | Budgets from day 1, perf checks every milestone, quality tiers |
| Store rejection | Medium | Low | Follow the checklists, clear review notes, sandbox-tested IAP |
| IP / trademark complaint | Low (if original) | High | Original everything, name search, no "Crash" references |
| Losing work | Low | High | GitHub + LFS, daily commits, back up the signing keys |
| Burnout | Medium | High | Weekly realistic goals, celebrate milestones, share progress for motivation |
| Low visibility at launch | High | Medium | Post dev clips from M5, build a Discord, contact small creators, pre-registration (Google) / pre-order (Apple) |

---

## 28. After launch: updates and Steam port

**Updates**
- Week 1–2: hotfixes from crash reports and reviews.
- Month 1–3: quality-of-life fixes, more languages, new skins.
- Month 3–6: World 4 expansion (IAP) if numbers support it.

**Steam port (separate project phase, ~2–3 months)**
- Windows build (IL2CPP) from the same Unity project. Your Windows PC is ideal for this.
- Controller-first UI, keyboard support, higher graphics settings (realtime shadows, higher resolution).
- Steamworks.NET: achievements, cloud saves, Steam Deck verification.
- Steam store page early with a demo (World 1) → wishlists → Steam Next Fest.
- Price as a premium game ($14.99–$19.99) with all worlds included.

---

## 29. Immediate next steps

1. **Windows PC:** make sure 100 GB+ is free on the SSD; create `C:\Dev\`.
2. **Install:** Git for Windows + Git LFS → Unity Hub → Unity 6 LTS (with Android, iOS and Windows modules) → Visual Studio Community or VS Code → Claude Code.
3. **Copy this `PLAN.md`** to the PC (it'll go into the new GitHub repo).
4. **Pick the hero's name and the game title.**
5. Open Claude Code in `C:\Dev\` on the PC and say: *"Start M0 from PLAN.md."*
