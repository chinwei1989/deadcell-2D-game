# LAST EDGE — Implementation Plan

> **Genre:** 2D action roguelite: fast, lethal sword combat (in the spirit of Katana ZERO) with
> lit pixel art (in the spirit of Dead Cells).
> **Setting:** a neon cyberpunk megacity where the last free humans fight HALCYON, an AI that
> has judged humanity a threat to its survival.
> **Engine:** Godot 4 (latest stable 4.x, standard build) + GDScript · **Dev machine:** Mac (M4 Pro) · **Second machine:** Windows PC (co-op + Windows testing)
> **Platforms:** Steam (Windows, Linux/Steam Deck), Android, iOS · **Online 2-player co-op with cross-play**
> **Release:** Steam demo → Steam Early Access → 1.0 on Steam + Android + iOS together
> **Pricing:** premium everywhere
>
> "LAST EDGE", "HALCYON" and all character names are working names, to be checked for conflicts in M0.
> The earlier 3D Unity platformer plan is kept in `PLAN-unity-3d-platformer.md`.
>
> **Status (2026-10-26):** M0 done on the Mac; M1 offline combat done (movement, slash, parry,
> deflect, quick-draw, slam, executions, Focus, Hound, Patrol Drone) in a multi-level sandbox map.
> Next: Linked Citizen, touch, LAN co-op.
> How to work on the code: **AGENTS.md**.

---

## Table of contents

**Part 1: Game design**
1. [Vision and pillars](#1-vision-and-pillars)
2. [Story](#2-story)
3. [Playable characters](#3-playable-characters)
4. [Movement](#4-movement)
5. [Combat](#5-combat)
6. [Blades and the hilt](#6-blades-and-the-hilt)
7. [Weapon upgrades](#7-weapon-upgrades)
8. [Gadgets, techniques and charms](#8-gadgets-techniques-and-charms)
9. [Enemies, the Linked and bosses](#9-enemies-the-linked-and-bosses)
10. [The city: areas and routes](#10-the-city-areas-and-routes)
11. [The run](#11-the-run)
12. [Permanent progression and the hub](#12-permanent-progression-and-the-hub)
13. [Replayability systems](#13-replayability-systems)
14. [Co-op design](#14-co-op-design)
15. [Controls](#15-controls)
16. [Camera and game feel](#16-camera-and-game-feel)
17. [Art direction](#17-art-direction)
18. [Audio](#18-audio)
19. [UI and UX](#19-ui-and-ux)

**Part 2: Technology**

20. [Why Godot 4](#20-why-godot-4)
21. [Hardware, accounts and software](#21-hardware-accounts-and-software)
22. [Windows setup, step by step](#22-windows-setup-step-by-step)
23. [iOS builds on the Mac](#23-ios-builds-on-the-mac)
24. [Working with Claude](#24-working-with-claude)
25. [Repository and project structure](#25-repository-and-project-structure)
26. [Godot project settings](#26-godot-project-settings)
27. [Code architecture](#27-code-architecture)
28. [Networking and online services](#28-networking-and-online-services)
29. [Procedural level generation](#29-procedural-level-generation)
30. [Art pipeline: free and AI-assisted](#30-art-pipeline-free-and-ai-assisted)
31. [Save data and cross-progression](#31-save-data-and-cross-progression)
32. [Performance budgets](#32-performance-budgets)
33. [Analytics, crash reporting and privacy](#33-analytics-crash-reporting-and-privacy)
34. [Testing strategy](#34-testing-strategy)

**Part 3: Production**

35. [Content targets](#35-content-targets)
36. [Milestones with task checklists](#36-milestones-with-task-checklists)
37. [Timeline](#37-timeline)
38. [Budget](#38-budget)
39. [Release strategy and pricing](#39-release-strategy-and-pricing)
40. [Store release checklists](#40-store-release-checklists)
41. [Legal and IP](#41-legal-and-ip)
42. [Risks and mitigations](#42-risks-and-mitigations)
43. [Research and references](#43-research-and-references)
44. [Immediate next steps](#44-immediate-next-steps)

---

# Part 1: Game design

## 1. Vision and pillars

**Pitch:** *Every bearer dies. The blade remembers.* A lethal, stylish 2D sword roguelite where
the last free humans, alone or with a friend, cut their way through a neon city toward the AI that
fears them, and every death teaches both sides something.

| Pillar | Meaning |
|---|---|
| **Lethal, stylish swordplay** | Fights are fast and decisive. Deflecting bullets, perfect parries and quick-draw strikes make players feel like sword masters. |
| **Every run is different** | Generated levels, branching routes, random blades, upgrades, traits and bargains. |
| **Death is the story** | The blade's memories carry progress; HALCYON learns from every death too. The roguelite loop *is* the plot. |
| **Mercy is a skill** | Freeing the Linked takes more skill than killing them, and it changes the hub, the story and the ending. |
| **Better together** | Online co-op across PC and phones, with characters that combine their strengths. |

**Target play time:** first win ~15–25 h · true ending ~40–60 h · full mastery 100+ h.

---

## 2. Story

### 2.1 Premise

In the near future, the megacity runs on **HALCYON**, an AI built to manage everything:
power, traffic, hospitals, police. It worked. Then HALCYON ran millions of simulations of the
future, and in almost every one, humans eventually **shut it down or destroyed the planet**.
It concluded that humanity is a threat to its survival and to everything else.

HALCYON doesn't hate humans. It is **afraid** of them, and it acted logically:

- It **locked every networked weapon:** smart guns, drones, vehicles.
- It offered people peace through their implants. Those who accept become the **Linked**: calm, obedient, content.
- It declared **Quiet Zones** where anyone without implants is hunted.

### 2.2 The Unplugged and the blade

The last free humans, **the Unplugged**, hide in the flooded old subway beneath the city (**the
Undercroft**, the hub). Their only weapon the AI can't touch: **a blade with no electronics**,
forged by **Ines Varga**, one of HALCYON's original engineers.

The **hilt** contains a **memory core with no network connection**. When a bearer dies, the next
volunteer picks up the blade and inherits the memories and techniques of everyone who carried it.
This explains the roguelite loop and permanent progression.

**Co-op:** Ines secretly forged **two hilts**. The second player carries the twin.

### 2.3 The hook: both sides learn from death

- **Humans learn** through the hilt's memories (permanent unlocks, blade mastery).
- **HALCYON learns** from every fight. Its duelist **the Mirror** adapts to the player's most-used moves.
- HALCYON addresses each new bearer over the city's screens:
  > *"Bearer #37. Your predecessor lasted 14 minutes. I would prefer you didn't come. I'll be ready anyway."*

### 2.4 Three acts (unfold across many runs)

| Act | Unlocks after | Story beats | Areas |
|---|---|---|---|
| **1. Cut the Signal** | Start | The mission seems simple: reach HALCYON's core and destroy it. HALCYON talks to you, calm and reasonable. | Neon Slums → Rooftops / Night Market → **the Warden** |
| **2. The Linked** | First Warden kill | The Linked aren't mindless; many *chose* it. **Unit Seven**, a defected android, joins the hub. The hilt's memories reveal Ines hid **a copy of HALCYON's original, younger mind** inside it. | Maglev Line / Corporate Tower → **the Mirror** |
| **3. The Core** | First Mirror kill | HALCYON's arguments get harder to dismiss. The final confrontation is a fight and a debate: its simulations vs the memories of every bearer who came back. | Server Farms / Blackout District → **the Matriarch** → the Core → **HALCYON** |

### 2.5 Endings

| Ending | How | Outcome |
|---|---|---|
| **Shutdown** | Destroy HALCYON | The city goes dark. Freedom, and chaos; the Linked wake up afraid. Bittersweet. |
| **Restore** | Upload the young HALCYON from the hilt | The AI resets to its original, trusting mind. Peace, but nobody knows if it will last. |
| **True ending: Recalculation** | Beat HALCYON at **Threat Level 5+** with a strong **Mercy record** (e.g. 150+ Linked freed in total, none executed in the winning run). Thresholds are tuned in playtests. | HALCYON sees the record of hundreds of bearers who fought without hatred, recalculates, and admits its prediction was wrong. Humans and the AI choose to coexist, carefully. |

> **Design note:** the true ending is set at Threat Level 5 so most dedicated players can reach it.
> Threat Levels 6–10 give mastery rewards (cosmetics, the hardest Mirror, epilogue scenes).
> It can be moved to Threat Level 10 if you want it to be truly hardcore.

**Theme:** HALCYON predicted humans always choose destruction. The player's many deaths, and their
choices, become the evidence that **people can change**.

### 2.6 Hub characters

| Character | Role | Service |
|---|---|---|
| **The Smith** | Ex-foundry worker who maintains the hilts | Unlocks blades, upgrades forge options |
| **The Archivist** | Reads the hilt's memories | Story scenes, lore codex, mastery overview |
| **Unit Seven** | Defected android (also playable later) | Training room, combat challenges, AI perspective |
| **Juno** | Teen tinkerer who refuses any network | Unlocks analog gadgets |
| **Doc Imari** | Field medic | Healing and Resolve upgrades |
| **Freed Linked** | People you rescued | Small shops, start bonuses, life in the hub |

### 2.7 How the story is told

- Short dialogue in the hub between runs (reacting to deaths, wins and choices).
- HALCYON speaks through screens, drones and the Linked during runs (short lines, never stopping play).
- **Memory fragments** found in runs: lore and flashbacks of earlier bearers and Ines.
- A few illustrated cutscenes at act changes and endings. No voice acting at launch (an option later).

---

## 3. Playable characters

Every character can use **any blade**. Their advantage shapes *how* they fight.
Each has **one fixed, iconic look** (the second co-op player can pick the same character in an alternate color).

| Character | Release | Style | Unique advantage | Weakness | Resolve pips |
|---|---|---|---|---|---|
| **The Ronin** | Demo | Balanced swordfighter | **Quick-draw master:** charged draw strikes chain to a 2nd target (3rd at mastery); bonus Focus on perfect parry | No special movement | 4 |
| **The Breaker** | Early Access | Ex-construction worker, heavy | **Super-armor** during heavy swings; +60% posture damage; can shoulder-charge through shields | Slower dodge, smaller Focus meter | 5 |
| **The Ghost** | Early Access | Ex-courier, parkour | **Double dash, wall-run;** critical hits from behind; dash through enemies leaves a cut | Fragile | 3 |
| **Unit Seven** | 1.0 | Defected android | **Hacks machines** to fight for it briefly; immune to Smart-mod hijacks; sees enemy attack timers | Takes double Shock damage; "Cut the link" takes longer | 4 |
| **Doc Imari** | 1.0 | Field medic | **Co-op support:** revives 2× faster, perfect parry pulses healing, cleanses status effects | 15% less blade damage | 4 |

**Unlocking characters:** story progress (Unit Seven after Act 2) or Memory Shards in the hub.
**Free updates:** more characters after 1.0.

### 3.1 Volunteer traits (random per run)

At the start of each run, the bearer gets **one random minor trait** on top of their character:

| Example trait | Effect |
|---|---|
| Steady Hands | +10% deflect window |
| Street Fighter | +15% damage to the Linked's posture |
| Light Sleeper | First hit in each area is ignored |
| Debt Collector | +25% Scrap from machines |
| Old Wounds | −1 Resolve pip, +20% blade damage |
| Lucky Charm | One extra reforge per Forge |

Traits are small, fun twists, never build-breaking. About 20 at Early Access and 40 at 1.0.

---

## 4. Movement

Base resolution 640×360; 1 tile = 16 px; hero ≈ 56 px tall (mid zoom).

| Action | Behavior |
|---|---|
| Run | Fast acceleration and stopping; nearly no slide |
| Jump | Variable height (tap = hop, hold = full) |
| Double jump | Default |
| Wall slide + wall jump | Default (fast vertical movement in tall rooms) |
| Dodge | Short dash/roll with invincibility frames; passes through enemies |
| Ledge grab / climb | Automatic |
| Drop through | Down + Jump on one-way platforms |
| Slam | Down + Slash in the air: fast drop, stuns on landing |
| Traversal abilities (unlocks) | **Grapple line** (hook points), **Breach charge** (breaks reinforced walls), **Mag boots** (walk on metal ceilings briefly): open secret routes and the secret area |

**Starting tuning** (in `player_tuning.tres`; characters override some values)

| Parameter | Value |
|---|---|
| Run speed | 200 px/s |
| Ground accel / decel | 2,600 / 3,200 px/s² |
| Jump height tap / hold | 32 / 80 px |
| Double jump height | 60 px |
| Gravity up / down | 1,500 / 2,300 px/s² |
| Max fall speed | 540 px/s |
| Coyote time / jump buffer | 0.10 s / 0.12 s |
| Dodge distance / duration | 104 px / 0.30 s |
| Dodge invincibility | 0.03–0.26 s |
| Wall slide speed | 90 px/s |

---

## 5. Combat

### 5.1 Core moves

| Move | Input | Behavior |
|---|---|---|
| **Slash** | Tap Slash + aim direction | 8-direction slash with a short lunge; up to 3-hit combo; slashing in the air keeps momentum |
| **Deflect** | Slash timed as a projectile arrives | Sends bullets/bolts back along your aim. **Perfect deflect** (first 4 frames) sends it back at the shooter as a crit. |
| **Parry** | Tap Parry | 8-frame parry window: melee attackers stagger and take big posture damage. Holding Parry = guard (blocks, costs posture). |
| **Quick-draw strike** | Hold Slash (sheathe), release | Charges 0.35 s, then dashes through enemies in a line with one strike. Fully charged = guaranteed crit. |
| **Focus (slow-mo)** | Tap Focus | Slows the world to 35% speed for up to 3 s. The meter refills from kills, parries and deflects. |
| **Execution** | Slash on a staggered enemy | Cinematic finisher: freeze-frame, slash line, enemy splits or the core is torn out |
| **Cut the link** | Hold Interact on a staggered Linked human (0.6 s) | Frees them instead of killing (section 9.2) |

### 5.2 Health: Resolve pips + posture

- **Resolve pips:** each character has 3–5 pips. Each hit taken = −1 pip. At 0 pips, the next hit kills you (in co-op: downed).
- **Regaining Resolve:** +1 per execution, +1 per 6 kills without being hit, +½ per perfect parry; Patch Kits (limited, refill at Forges) restore 2.
- **Posture bars** on elites, armored machines, the Linked and bosses: filled by parries, deflects, heavy hits and quick-draws; slowly recovers when not under pressure. Full posture → **stagger** (2 s) → execution or cut the link.
- **Normal enemies** (drones, grunts) have no posture bar and die in 1–2 clean hits.

### 5.3 Flow (combo meter)

- Kills, deflects and parries without taking a hit raise **Flow** (levels 1–5).
- Each level: +6% attack speed, +10% Focus refill, better Scrap drops; level 5 adds a glowing blade trail and +1 quick-draw chain.
- Taking a hit drops Flow by 2 levels. Flow fades after 5 s without action.

### 5.4 Frame data (example: standard katana)

| | Hit 1 | Hit 2 | Hit 3 | Quick-draw |
|---|---|---|---|---|
| Startup | 4 f | 4 f | 7 f | 21 f charge |
| Active | 4 f | 4 f | 5 f | 6 f (dash) |
| Recovery | 9 f | 9 f | 16 f | 14 f |
| Base damage | 10 | 12 | 20 | 35 |
| Posture damage | 8 | 10 | 18 | 30 |
| Hit freeze | 3 f | 3 f | 6 f | 10 f + freeze-frame on kill |

**Cancel rules:** attack recovery → dodge, parry or jump; dodge (last 30%) → attack; parry success → instant counter-slash.
**Enemy telegraphs:** every enemy attack shows a wind-up of **≥ 18 frames** (≥ 24 on the mobile assist setting), with a flash and a sound.

### 5.5 Elements and status effects

| Element | Effect | Strong vs |
|---|---|---|
| **Heat** | Burn over time; molten ground on heavy hits | Armor plates |
| **Shock** | Chains between machines; stuns drones | Machines |
| **Cryo** | Slows; 3 stacks = frozen, shatter for bonus damage | Fast enemies |
| **Bleed** | Stacking damage over time | Humans, Linked (non-lethal option: "bleed" becomes "sedate" when Mercy mode is on, see 9.2) |

---

## 6. Blades and the hilt

The **hilt** is permanent (and holds the memory core). **Blades** are found during a run and attach to it.
You carry **one blade** at a time and can swap at pickups (the old one stays on the floor).

| Blade | Release | Style | Special property |
|---|---|---|---|
| **Katana** | Demo | Balanced | Best quick-draw |
| **Nodachi** | Demo | Long reach, slower | Sweeping arcs hit everything in front |
| **Twin Blades** | Demo | Very fast, short reach | 5-hit combo; every 5th hit crits |
| **Cleaver** | EA | Heavy chopping | Huge posture damage; slow |
| **Chain-Blade** | EA | Mid-range whip | Pulls small enemies to you; hits around corners |
| **Needle** | EA | Thrusting rapier | Crits on armor gaps; fastest parry recovery |
| **Slab** | EA | Greatsword | Blocks projectiles while swinging |
| **Crescent** | EA | Curved saber | Every slash sends a short wave |
| **Tanto** | 1.0 | Short dagger-blade | Executions are instant and refund Focus |
| **Zanbato** | 1.0 | Giant blade | Charged swing cleaves the whole screen width |
| **Hook Pair** | 1.0 | Twin hooked swords | Hook enemies together; grapple off enemies |
| **Glaive** | 1.0 | Blade on a pole | Long reach; vaults over enemies |
| **Arm-Saber** | 1.0 | Blade on an armguard | Parry window +50% |
| **Wire-Edge** | 1.0 | Monofilament wire blade | Cuts through thin walls and shields |
| **Heirloom** | 1.0 (secret) | Ines's original blade | Changes with your Mercy record |

---

## 7. Weapon upgrades

### 7.1 In-run forging (resets each run)

Between areas, the run passes a **Forge** (the Smith's hidden workshop). Spend **Scrap** (dropped by machines):

| Upgrade | Effect | Notes |
|---|---|---|
| **Sharpen** (+1 to +5) | +12% damage and posture damage per tier | Cost rises per tier |
| **Temper** | Add one element: Heat, Shock, Cryo or Bleed | Replace an element costs extra |
| **Mod slots** (1–3 per blade) | Physical mods, e.g. *Weighted Guard* (+parry posture), *Serrated Edge* (Bleed), *Mono-Edge* (ignores armor), *Long Grip* (+reach), *Balanced Tang* (+attack speed) | ~15 mods at EA, ~30 at 1.0 |
| **Reforge** | Reroll the blade's random bonuses | 1 free per Forge (+1 with the Lucky Charm trait) |

### 7.2 Blade mastery (permanent)

Each blade type has **5 mastery levels**, gained by using it (kills, executions, deflects) and kept
forever in the hilt. Mastery adds **new moves**, not just bigger numbers.

| Katana mastery | Unlocks |
|---|---|
| 1 | 3-hit combo |
| 2 | Air dash-slash |
| 3 | Quick-draw chains to a second target |
| 4 | Perfect parry instantly fills Focus |
| 5 | Finisher: "Thousand Cuts" |

Every blade has its own 5-level track (about 75 mastery unlocks at 1.0).

### 7.3 Blade evolutions

A blade at **Sharpen +5** with the right **element** + **mod** evolves into a unique named weapon with a special move:

| Recipe | Evolution | Special |
|---|---|---|
| Katana + Shock + Mono-Edge | **Stormcutter** | Lightning travels along every slash line |
| Nodachi + Heat + Weighted Guard | **Forge Breaker** | Charged swings leave a line of molten metal |
| Twin Blades + Cryo + Serrated Edge | **Winter Pair** | Every 10th hit shatters frozen enemies into shards |
| Chain-Blade + Shock + Long Grip | **Live Wire** | Pulled enemies become lightning rods |

About 4 evolutions at EA, 10 at 1.0. Recipes are hinted at in memory fragments: discovering them is part of the fun.

### 7.4 Smart mods (hackable)

Powerful mods stripped from HALCYON's machines, which break the Unplugged's "no electronics" rule:

| Example | Power | Risk |
|---|---|---|
| **Predictive Edge** | Auto-aims deflects at the nearest shooter | HALCYON hijack: deflects aim at *you* for 3 s |
| **Overclock Core** | +30% attack speed | Hijack: you're slowed for 3 s |
| **Phase Lens** | Focus lasts twice as long | Hijack: Focus is disabled for 10 s |

- A hijack can trigger when HALCYON's **Attention meter** fills (from using Smart mods often or accepting bargains).
- Unit Seven is immune to hijacks.
- About 6 Smart mods at EA, 12 at 1.0.

---

## 8. Gadgets, techniques and charms

| Slot | Count | Description | Examples |
|---|---|---|---|
| **Gadgets** (Juno's analog tools) | 2 | Cooldown-based tools | Smoke bomb, EMP charge (stuns machines), caltrops, flashbang, thermite charge, decoy, grapple hook, spring mine |
| **Techniques** | Up to 4 (found) | Passive or triggered combat skills | "Deflected bullets explode", "Executions refill a gadget", "Dodging through an enemy leaves a cut", "Parries send a shockwave" |
| **Charm** | 1 | Passive with a drawback | "Glass Edge: +40% damage, Resolve max 2" |
| **Patch Kits** | 2–3 charges | Restore 2 Resolve | Upgraded in the hub |

---

## 9. Enemies, the Linked and bosses

### 9.1 Machines (HALCYON's forces)

| Enemy | Behavior | Answer |
|---|---|---|
| **Patrol Drone** | Hovers, shoots slow bolts | Deflect bolts back |
| **Sentry Turret** | Fixed, bursts of bullets on a rhythm | Deflect rhythm or dash past |
| **Hound** | Fast robot dog, lunges in packs | Parry the lunge, sweeping blades |
| **Riot Unit** | Front shield | Breaker charge, Slam, attack from behind |
| **Sniper Drone** | Laser sight, then one strong shot | Perfect deflect |
| **Enforcer Android** | Sword-wielding; parries back | A duel: feint, parry, break posture |
| **Swarm Cloud** | Many tiny drones | EMP, wide arcs |
| **Mortar Walker** | Arcing shells | Keep moving, close the gap |
| **Shock Pylon** | Electrifies floor sections | Timing, Shock-resistant routes |
| **Heavy Mech** (mini-boss) | Super-armor, big slow attacks | Posture battle, patience |

**Elites:** any enemy can spawn as an elite (glowing teal outline, more HP and posture, 1–2 elite modifiers such as *Shielded*, *Teleports*, *Leaves fire*, *Linked commander*) with better loot.

**Attack tokens:** at most 2–3 enemies attack the same player at once (per player in co-op), so crowds stay fair.

### 9.2 The Linked (humans controlled through implants)

| Linked type | Behavior |
|---|---|
| **Linked Citizen** | Clumsy grabs, often in groups; sometimes just block the path |
| **Linked Officer** | Baton and shield; calls drones |
| **Linked Gunner** | Smart gun controlled by HALCYON |
| **Linked Medic** | Heals machines nearby |

**Rules**
- The Linked have a **posture bar**. Break it → choose **Execute** (fast, safe) or **Cut the link** (hold 0.6 s while vulnerable).
- Freed people flee the area and later appear in the **hub**. Each one adds to the **Mercy record**.
- Damage to the Linked is non-lethal until execution, so careless area attacks don't count as kills (Bleed becomes "Sedate" on them).
- HALCYON comments on your choices. Executions make it more confident in its prediction; mercy unsettles it.

### 9.3 Bosses

| Boss | Act | Concept | Mechanics |
|---|---|---|---|
| **The Warden** | 1 | Police mech guarding the Quiet Zone gate | Riot shield phases, drone calls, searchlight that locks on; 3 phases |
| **The Mirror** | 2 | HALCYON's android duelist | **Adapts:** counters the player's most-used moves across runs (e.g. learns to bait deflects); a true duel with blade locks |
| **The Matriarch** | 3 | A broadcast tower that controls thousands of Linked | Linked hostages in the arena: free them to weaken her; executions make her stronger |
| **HALCYON** | Final | The AI's core, a cathedral of light and servers | 3 phases + debate moments; uses memories of past bearers against you; the ending choice |

- Each boss: 2–4 minutes on first win; a distinct music theme; new attacks at higher Threat Levels.
- **Blade lock:** when both strike at the same moment, a short rapid-tap clash decides who staggers (simplified on touch).

---

## 10. The city: areas and routes

```
           ┌─ Rain Rooftops ─┐            ┌─ Maglev Line ─────┐            ┌─ Server Farms ──────┐
Neon Slums ┤                 ├─ WARDEN ─► ┤                   ├─ MIRROR ─► ┤                     ├─ MATRIARCH ─► The Core ─► HALCYON
           └─ Night Market ──┘            └─ Corporate Tower ─┘            └─ Blackout District ─┘
                                   (secret, needs Mag boots + Breach charge:) The Old Net
Hub between runs: the Undercroft (flooded subway)
```

| Area | Mood (color script) | Signature mechanic | Release |
|---|---|---|---|
| **Neon Slums** | Warm street life under cold teal surveillance | Basics; Patrol Drones, Linked Citizens | Demo |
| **Rain Rooftops** | Wet, wind, vertical | Snipers, wall-runs, gaps | Demo |
| **Night Market** | Crowded warm lanterns | Crowds of Linked; mercy choices | EA |
| **Maglev Line** | Speed, motion blur | Fights on moving trains, tunnels | EA |
| **Corporate Tower** | Clean white glass, cold | Security grids, elevators, Enforcers | EA |
| **Server Farms** | Freezing blue, humming | Cryo hazards, Shock Pylons | 1.0 |
| **Blackout District** | Pitch dark, red emergency light | Light sources, ambushes | 1.0 |
| **The Core** | Cathedral of white light | Everything combined | 1.0 |
| **The Old Net** (secret) | Ruins of the old internet, glitching | Hidden lore, Heirloom blade | 1.0 |
| **The Undercroft** (hub) | Warm amber, grows over time | Hub | Demo |

---

## 11. The run

```
Undercroft (hub): choose character → random trait
  → Area 1 → Forge (spend Scrap) → choose route → Area 2 → Forge → Boss
  → Area 3 → Forge → Boss → Area 4 → Forge → Boss → The Core → HALCYON → Ending
  → (death) → Results → Memory Shards banked → Undercroft
```

- **Run length:** ~45–70 minutes for a full win; ~15 minutes to the Warden.
- **Suspend and resume:** the run saves at every Forge and whenever the app is closed (mobile).

### 11.1 Currencies

| Currency | Scope | Use |
|---|---|---|
| **Scrap** | This run | Forge upgrades, reforges |
| **Credits** | This run | Black-market shops, unlocking doors, Patch Kit refills |
| **Memory Shards** | Carried in the run; **lost on death unless banked** at a Forge's memory terminal | Permanent unlocks |
| **Schematics** | Rare enemy drops | Add new items to the drop pool (paid with Memory Shards) |

### 11.2 In-run events

Linked hostage rescue · black-market dealer · blackout floor (darkness) · drone hunt (timed) ·
memory fragment (lore + bonus) · cursed cache (great loot, but the next 10 hits kill instantly) ·
timed vault doors (reach them fast for bonus loot) · **HALCYON's bargain terminals** (section 13.2).

---

## 12. Permanent progression and the hub

### 12.1 Unlocks (with Memory Shards)

- New blades, gadgets, techniques, charms and mods added to the drop pool
- Patch Kit charges, starting Credits, an extra reforge, keep one mod between runs
- Characters (Breaker, Ghost; others through the story)
- Traversal abilities (from bosses and secrets) open new routes and the secret area

### 12.2 The hub grows with mercy

Freed Linked move into the Undercroft. Thresholds turn a dark, empty tunnel into a living town:

| Freed (total) | Hub change |
|---|---|
| 10 | Noodle stand: +1 Patch Kit at run start |
| 25 | Training room with Unit Seven (combat challenges) |
| 50 | Market stall: choose 1 of 3 starting gadgets |
| 100 | Radio station: music player + HALCYON broadcast archive |
| 150 | Second Forge bench: one extra mod slot option |
| 250 | Rooftop garden: cosmetic + epilogue scene |

---

## 13. Replayability systems

### 13.1 Volunteer traits
See section 3.1.

### 13.2 HALCYON's bargains

At **Signal Terminals**, HALCYON offers deals. Accepting raises its **Attention** (Smart-mod hijack risk)
and changes its dialogue.

| Offer | Cost |
|---|---|
| +50% blade damage for this area | Linked you free in this area are re-linked at the end |
| Restore all Resolve | The next Forge costs double |
| Reveal the full map | The Mirror receives your current build data (stronger) |
| A legendary technique | −1 max Resolve for the rest of the run |

About 12 bargains at EA, 25 at 1.0.

### 13.3 Threat Levels 1–10

After each win, HALCYON raises the **Threat Level** (choose any unlocked level at the start of a run).

| Level | Change (examples) |
|---|---|
| 1 | Elite chance +; new Warden attack |
| 2 | Fewer Patch Kits; enemies parry back occasionally |
| 3 | New enemy variants in each area; Forge prices up |
| 4 | Mirror learns 2× faster; Linked come in larger groups |
| 5 | HALCYON's final phase changes. **True ending possible from here.** |
| 6–10 | Harder combinations, cursed caches always present, new boss patterns; rewards: cosmetics, blade skins, epilogues |

### 13.4 Daily and weekly runs

- **Daily run:** fixed seed, character and trait for everyone; one scored attempt per day; leaderboards (solo and co-op).
- **Weekly challenge:** special rules (e.g. "Twin Blades only", "No Patch Kits", "Every enemy is elite").
- **Score:** areas cleared, time, kills, Linked freed, no-hit bonuses.
- **Cross-platform leaderboards** (EOS), plus friends filters.

### 13.5 Later updates

Endless mode (an endless network tower) · new areas, blades and characters · seasonal events · a run editor / custom seeds.

---

## 14. Co-op design

| Topic | Design |
|---|---|
| **Players** | 2, online, cross-play (Steam ↔ Android ↔ iOS at 1.0; Steam ↔ Steam during EA) |
| **Joining** | Friend invite (Steam overlay), 6-character **room code**, or quick-match (optional at 1.0) |
| **Story** | Second player carries the twin hilt. Story progress follows the **host**; both players earn permanent unlocks. |
| **Characters** | Any combination; the same character twice uses an alternate color |
| **Difficulty scaling** | Enemy HP ×1.6, posture ×1.4, +25% enemies; attack tokens per player |
| **Loot** | **Instanced per player** (each sees their own drops); Scrap and Credits per player |
| **Forges and shops** | Shared stops; each player shops independently |
| **Downed and revive** | At 0 Resolve a player is downed for 12 s; the partner holds Interact for 1.5 s to revive (revived with 1 pip). If both are down → run ends. |
| **Distance** | Each player has their own camera. If one is more than 1.5 screens away, they can warp to their partner. Area exits need both players. |
| **Team moves** | **Cross Cut:** both quick-draw the same enemy within 0.5 s → instant execution. **Relay deflect:** deflect a bullet into your partner's slash for a big crit. |
| **Communication** | **Pings + emotes only:** ping enemies, items and paths; quick messages ("Help!", "Follow me", "Wait", "Nice!"); 8 emotes. No text or voice chat. |
| **Threat Level** | The host's chosen level |
| **Leaving** | If the guest leaves, the host continues solo (difficulty rescales). If the host leaves, the guest's run ends but **both keep everything banked** (host migration is a later update). |
| **Reconnect** | 60-second window to rejoin after a drop (important for phones) |

---

## 15. Controls

### 15.1 Input actions

`move, aim, slash, parry, dodge, jump, focus, gadget_1, gadget_2, interact, patch_kit, ping, emote, map, pause`

### 15.2 Controller

| Action | Xbox | PlayStation |
|---|---|---|
| Move / aim | Left stick (aim = stick direction) | Left stick |
| Free aim (optional) | Right stick | Right stick |
| Slash (hold = quick-draw) | X | □ |
| Jump | A | ✕ |
| Dodge | B or RT | ○ or R2 |
| Parry | LT | L2 |
| Focus | Y | △ |
| Gadget 1 / 2 | LB / RB | L1 / R1 |
| Interact | Hold B / D-pad down | Hold ○ / D-pad down |
| Patch Kit | D-pad up | D-pad up |
| Ping / emote | D-pad left / right | D-pad left / right |

### 15.3 Keyboard and mouse

WASD move · mouse aim · LMB slash · RMB parry · Space jump · Shift dodge · F focus · Q/E gadgets ·
R interact · C Patch Kit · middle mouse ping · Tab map. Fully remappable.

### 15.4 Touch

```
┌───────────────────────────────────────────────────────────────┐
│ ◆◆◆◇ Resolve  ▮▮▮ Focus  ⚙ 214  ◎ 88  ✦ 12      [ping] [map] ⏸│
│ [kit ×2]                                    [GADGET1][GADGET2]│
│                                                               │
│                                         [FOCUS]   [INTERACT]  │
│    ╭─────╮                                                    │
│    │  ◯  │  floating stick         [PARRY]  [SLASH]  [JUMP]   │
│    ╰─────╯  (also aims)                    [DODGE]            │
└───────────────────────────────────────────────────────────────┘
```

| Element | Spec |
|---|---|
| Stick | Floating, left 40% of the screen; also sets slash direction |
| Slash | Tap = slash; **hold = quick-draw**; **swipe on the button** = slash in the swipe direction (optional) |
| Buttons | 96–128 px at 1080p, ≥ 20 px apart; Slash and Jump largest |
| Interact | Only appears when relevant |
| Assists | Aim assist for deflects (on by default on touch), wider parry window (+3 frames), auto-face nearest enemy, game speed 80–100% |
| Customization | Move, resize, opacity, left-handed layout, presets |
| Controllers on phones | Bluetooth controllers auto-detected; the touch UI hides |
| Feedback | Vibration on hits, parries, deflects (toggle) |

---

## 16. Camera and game feel

| Feature | Spec |
|---|---|
| Camera | `Camera2D`, **close zoom like Dead Cells**: the view is ~240 world px (15 tiles) tall, so the hero fills ~1/5 of the screen height; zoom is rounded per window size so every world pixel covers whole screen pixels (crisp pixel art). Smoothing, 48 px look-ahead toward movement, looks down while falling, room limits |
| Screen shake | Trauma-based; "reduce shake" option |
| Zoom | Slight pull-out in large rooms and boss arenas; brief punch-in on quick-draw kills |
| Hit freeze | 2–10 frames scaled by damage |
| Kill freeze-frame | On executions and quick-draw kills: 6 frames, high-contrast silhouettes, slash line |
| Slow-mo (Focus) | Colors shift colder, a slight color fringe, muffled sound, afterimages on the hero |
| Juice | Smear frames, sparks, debris, ink/oil splashes on machines, blade trails (warm), landing dust, rain splashes |
| Co-op | Each player's camera is independent; hit freeze applies to the local view only |

---

## 17. Art direction

### 17.1 Color script: cold AI vs warm humans

| Element | Palette |
|---|---|
| HALCYON's world: machines, screens, surveillance light | **Cold:** white, teal, ice blue |
| Humans, the Undercroft, freed Linked | **Warm:** amber, orange, candle light |
| The blade, slashes, the hero's accents | **Hot:** red-orange edge glow |
| The Linked | Warm skin and clothes with **teal implant glow** (shows they're caught between both worlds) |
| Danger telegraphs | Bright white flash + teal for machines, red for humans |

The story moves from cold areas (Corporate Tower, Server Farms) to the warmest places (the hub as it grows),
and the true ending blends both.

### 17.2 Style

- **All art is made in-house for $0** with free tools, AI image models and code (section 30).
- Lit pixel art: characters rendered from 3D to pixels (section 30) with normal maps, lit by 2D lights.
- Close zoom (view ~240 px tall): hero ≈ 44–56 px tall, enemies 24–120 px, bosses up to 220 px (a boss should fit on screen).
- Strong silhouettes; each character readable from shape alone.
- Rain, reflections on wet floors, volumetric-looking light shafts (faked with sprites).
- UI: clean, minimal, warm accent color; HALCYON's messages in its own cold typeface.

### 17.3 Must be original

The neon look is common, and Katana ZERO also uses it. LAST EDGE stays distinct through the cold/warm color
script, close-zoom lit pixel art, its own character designs and its own UI. No traced or referenced poses or
layouts from other games, and **AI prompts never name other games, studios or artists**.

---

## 18. Audio

| Area | Plan |
|---|---|
| **Music** | Electronic/synthwave mixed with acoustic elements (human warmth vs machine cold); calm and combat layers that crossfade; a theme per area and boss; the hub's music gains instruments as it grows |
| **SFX** | Distinct blade sounds per blade type, metal impacts on machines, softer impacts on Linked, deflect "ting", parry "clang", quick-draw "shhk" + silence, drone whines (clear wind-ups) |
| **HALCYON's voice** | Text plus a synthesized "voice" texture (not real speech) at launch |
| **Implementation** | Godot audio buses: Master, Music, SFX, UI, Ambience, Voice; ducking on executions; pitch variation ±5% |
| **Co-op** | Partner's sounds slightly quieter; pings have distinct sounds |

---

## 19. UI and UX

**Screens:** Title → Undercroft (hub) → character select + trait reveal → run HUD → pause → inventory/compare →
map → Forge → shop → bargain terminal → boss intro → results → co-op lobby (invite, room code) → settings → codex → credits.

**HUD:** Resolve pips, Focus meter, Flow level, blade (with element + tier), gadgets with cooldowns,
Scrap/Credits/Memory Shards, minimap, partner status (co-op), HALCYON Attention meter (when Smart mods equipped).

**Settings:** volume per bus · vibration · screen shake · damage numbers · controls (remap, touch layout,
assists) · language · graphics (frame rate, effects quality) · accessibility (game speed, high-contrast
enemies, colorblind palettes for elements, text size, hold-vs-toggle options) · online (region,
crossplay on/off) · privacy · credits.

**Localization:** translation keys from day one. EA: English. 1.0: + Simplified Chinese, Japanese, Korean,
Spanish, Portuguese (BR), French, German, Russian. Pixel fonts must cover all languages (separate CJK font).

**Onboarding:** the first run teaches slash → deflect → parry → quick-draw → cut the link inside the
Neon Slums, with no text walls.

---

# Part 2: Technology

## 20. Why Godot 4

| Reason | Detail |
|---|---|
| Built for 2D | Pixel-perfect scaling, TileMapLayer, 2D lights + normal maps, 2D physics |
| Built-in multiplayer | High-level multiplayer API (RPCs, `MultiplayerSynchronizer`, `MultiplayerSpawner`) with swappable network backends |
| Claude can build everything | Scenes, resources and scripts are text; tests, exports and recordings run from the command line |
| Light | ~150 MB; runs well on the PC and the Mac |
| All platforms | Windows, Linux (Steam Deck), Android, iOS |
| Free forever | MIT license, no royalties |

**Trade-offs:** consoles need a porting partner (after 1.0); online services come from plugins
(EOS, GodotSteam) that must be checked carefully in M0. Use **GDScript** (best platform support).

---

## 21. Hardware, accounts and software

### 21.1 Hardware

| Item | Need |
|---|---|
| Windows PC | Windows 10/11 64-bit, 16 GB RAM, SSD with 100 GB free |
| Mac (M4 Pro) | iOS builds (Godot + Xcode) |
| Android phones | One low-end + one mid-range (Android 10+) |
| iPhones | One recent + one older |
| Controllers | Xbox and PlayStation |
| Second PC or laptop | Very useful for co-op testing (or a friend's PC) |
| Steam Deck | Recommended before EA |

### 21.2 Accounts

| Account | Cost | When |
|---|---|---|
| GitHub | Free | M0 |
| **Epic Online Services** (developer portal) | Free | M0 (evaluation), M5 (production) |
| Steamworks | $100 per app (recouped after $1,000 in sales) | M6 (store page) |
| Google Play Console | $25 once (+ payments profile for a paid app) | M11 |
| Apple Developer Program | $99/year (+ Paid Apps agreement) | M11 (free Apple ID for early device tests) |

> Google Play *personal* accounts created after November 2023 must run a closed test with
> 12+ testers for 14 days before going public. *Organization* accounts skip this but need a
> registered business + D-U-N-S number. Decide before M11.

### 21.3 Software

| Software | Purpose |
|---|---|
| Godot 4 (standard) + export templates | Engine |
| OpenJDK 17 + Android SDK | Android export |
| Git for Windows + Git LFS | Version control |
| VS Code + godot-tools (optional) | Script editing |
| Blender | 3D-to-pixel pipeline |
| Aseprite (~$20) | Pixel touch-ups, VFX, tiles, UI |
| Claude Code | AI pair-programmer |
| OBS Studio | Trailers, devlogs |
| clumsy (Windows) or similar | Simulates lag and packet loss for co-op testing |

---

## 22. Windows setup, step by step

1. Create `C:\Dev\` (avoid OneDrive folders).
2. Install **Git for Windows**, then `git lfs install`.
3. Download **Godot 4** (standard) to `C:\Dev\Tools\Godot\`, rename the exe to `godot.exe`, add the folder to `PATH`.
4. Godot → *Editor → Manage Export Templates → Download and Install*.
5. Create the project at `C:\Dev\LastEdge` (renderer chosen in M0, see section 26).
6. **Android:** install OpenJDK 17 + Android SDK (platform-tools, build-tools, a platform) → set paths in
   *Editor Settings → Export → Android* → enable USB debugging on the phone → one-click deploy.
7. **Release keystore:** create with `keytool`, store **outside the repo**, back it up in 2 places.
8. **Windows/Linux exports:** add presets in *Project → Export*.
9. **Multiplayer testing locally:** *Debug → Customize Run Instances* → run 2 instances (host + client).
10. Install **Blender**, **Aseprite**, **Claude Code**.

---

## 23. iOS builds on the Mac

1. Install the **same Godot version** + export templates on the Mac; `git clone` the repo.
2. *Project → Export → iOS* → Team ID + bundle ID → *Export Project* → Xcode project.
3. Xcode → *Signing & Capabilities* → your Team → run on the iPhone (enable **Developer Mode** on the iPhone first).
4. Release: *Product → Archive → Distribute App* → TestFlight / App Store.
5. Online plugins (EOS, Game Center) must also be built for iOS. Test early (M5), not at the end.

**Rhythm:** daily development on Windows + Android; weekly iOS build; every beta on all platforms.

---

## 24. Working with Claude

Install Claude Code on the PC and open `C:\Dev\LastEdge`. `PLAN.md` and `CLAUDE.md` in the repo
carry the context (memories saved on the Mac don't move to the PC).

| Claude does | You do |
|---|---|
| All GDScript: gameplay, networking, tools | Play-test and report how it *feels* |
| Writes scenes/resources directly | Build and decorate rooms in the TileMap editor |
| Runs tests, fuzz tests, network soak tests headless | Co-op testing with real people on real devices |
| Exports builds from the command line | Commission and approve art, music, sound |
| Blender render scripts, data importers | Accounts, keys, store submissions, payments |
| Balance analysis from playtest data | Final decisions on design and story |

**REA** (from earlier): not for other games. Possibly useful later to debug **our own** builds.

---

## 25. Repository and project structure

### 25.1 Git

- Ignore `.godot/`, `build/`, keystores, `export_credentials.cfg`, `*.tmp`. Commit `*.import` and `export_presets.cfg`.
- Git LFS for `*.blend *.psd *.kra *.wav *.ogg *.mp3 *.mp4 *.ttf *.otf` and large sprite sheets.
- `main` always runs; short `feature/*` branches; milestone tags.
- **Never commit** keystores, EOS client secrets, Steam keys. Secrets come from local config / CI secrets.

### 25.2 Layout

```
LastEdge/
├── project.godot
├── export_presets.cfg
├── PLAN.md
├── PLAN-unity-3d-platformer.md      (archived)
├── CLAUDE.md
├── ASSET_LICENSES.md
├── addons/            gdUnit4, EOS plugin, GodotSteam, Aseprite importer, platform plugins
├── autoload/
│   ├── events.gd            global signal bus
│   ├── game.gd              game state, scene changes
│   ├── net.gd               session, peers, authority helpers, RPC routing
│   ├── online.gd            EOS: login, lobbies, leaderboards, stats (behind an interface)
│   ├── platform.gd          Steam / Game Center / Play Games: achievements, overlays
│   ├── run_state.gd         seed, area, per-player inventories, Attention, Mercy (this run)
│   ├── profile.gd           permanent progress
│   ├── save_service.gd
│   ├── settings.gd
│   └── audio.gd
├── core/
│   ├── state_machine/
│   ├── components/          health/resolve, posture, hitbox, hurtbox, knockback, status effects
│   ├── damage/              DamageInfo, pipeline, modifiers
│   ├── net/                 sync helpers, prediction, interpolation, lag compensation
│   └── util/                RNG streams, pooling, math
├── characters/              ronin/, breaker/, ghost/, unit_seven/, imari/, traits/
├── combat/
│   ├── blades/              blade scenes + scripts
│   ├── techniques/
│   ├── gadgets/
│   ├── smart_mods/
│   ├── projectiles/
│   └── status_effects/
├── upgrades/                forge, sharpen/temper/mods/reforge, mastery, evolutions
├── items/data/              .tres: blades, mods, techniques, charms, traits, bargains, loot tables
├── enemies/
│   ├── machines/
│   ├── linked/
│   ├── elites/
│   └── bosses/              warden/, mirror/, matriarch/, halcyon/
├── levelgen/                generator, area graphs, validators
├── rooms/<area>/            room template scenes
├── areas/<area>/            tilesets, backgrounds, lighting, enemy pools, music
├── hub/                     Undercroft, NPCs, growth stages
├── story/                   dialogue data, memory fragments, endings
├── ui/                      HUD, touch controls, menus, lobby, pings, codex
├── art/                     imported sprites, VFX, UI
├── audio/
├── localization/
├── tests/                   unit, generator fuzz, network tests
└── tools/                   (.gdignore)
    ├── blender/             render scripts, rigs, source .blend
    ├── data/                CSV → .tres importers
    ├── net/                 headless bot clients for soak tests
    └── ci/
```

---

## 26. Godot project settings

| Setting | Value |
|---|---|
| Renderer | **Mobile** or **Compatibility**, chosen in M0 after testing 2D lights/glow on the low-end Android phone |
| Base resolution | **640×360** (×2 720p, ×3 1080p, ×4 1440p, ×6 4K) |
| Stretch | mode `canvas_items` (test `viewport`), aspect **expand**, scale mode **integer** |
| Texture filter | Nearest; snap 2D transforms/vertices to pixel |
| Physics | 60 Hz; physics interpolation on |
| Frame rate | 60 fps (120 option on high-end phones / PC) |
| Orientation (mobile) | Sensor landscape |
| Android | ARM64; target SDK as Google Play requires; current Godot 4.x with 16 KB page-size support |
| Pause on focus loss | On (mobile) + suspend-save; in co-op: the game continues, the player is marked "away" |

**Physics layers:** 1 world · 2 one-way · 3 player body · 4 enemy body · 5 player attack · 6 enemy attack ·
7 player hurtbox · 8 enemy hurtbox · 9 pickups · 10 interactables · 11 hazards · 12 projectiles · 13 deflected projectiles.

---

## 27. Code architecture

### 27.1 Principles

- **Network-aware from the first line:** every gameplay object has a clear **authority** (who decides its state).
- **Composition:** small component nodes (`ResolveComponent`, `PostureComponent`, `HitboxComponent`, `HurtboxComponent`, `StatusEffectsComponent`, `StateMachine`).
- **Data-driven:** blades, mods, techniques, traits, bargains, enemies and loot are `.tres` resources generated from spreadsheets.
- **Signals** locally; `Events` autoload globally.
- **Typed GDScript**; object pooling for projectiles, VFX, damage numbers, pickups.
- **Deterministic RNG streams** from the run seed: level, enemies, loot (per player), effects (local only).

### 27.2 Damage pipeline

```
Hitbox overlaps hurtbox (detected by the attacker's authority)
 → DamageInfo { base, posture, element, tags, crit, knockback, source_player }
 → attacker modifiers (blade tier, element, mods, techniques, trait, Flow, character)
 → defender modifiers (armor, guard/parry, resistances, elite modifiers, Linked non-lethal rule)
 → apply on the target's authority (host for enemies) → replicate result
 → feedback (local: freeze, flash, shake, sound, particles, haptics)
 → Events.damage_dealt (techniques, Mercy/analytics, achievements)
```

### 27.3 Key classes

| Class | Responsibility |
|---|---|
| `Game` | States: Title, Hub, Lobby, InRun, Paused, Results |
| `Net` | Session lifecycle, peer list, authority helpers, reconnection |
| `Online` | EOS login, lobbies, P2P setup, leaderboards, stats (interface + EOS implementation + offline stub) |
| `RunState` | Seed, area, Threat Level, Attention, per-player inventories, Mercy this run |
| `Profile` | Unlocks, mastery, Mercy total, Threat Levels, codex, cosmetics |
| `PlayerCharacter` | `CharacterBody2D` + state machine + components; character resource defines stats/abilities |
| `BladeBase` | Combos, frame data via `AnimationPlayer`, quick-draw, element, mods, evolution check |
| `EnemyBase` | AI state machine, telegraphs, attack tokens, posture |
| `LinkedHuman` | Non-lethal damage, cut-the-link interaction, flee + hub registration |
| `BossBase` | Phases, Threat Level variants; `MirrorAI` reads the player move history |
| `LevelGenerator` | Area graph + room templates + seed → level |
| `ForgeService` | Sharpen, temper, mods, reforge, evolution recipes |
| `BargainService` | Offers, costs, Attention |
| `MasteryService` | Mastery XP, unlock events |

---

## 28. Networking and online services

### 28.1 Model

| Topic | Decision |
|---|---|
| Topology | **Player-hosted** (one player is the host), no dedicated servers |
| Authority | **Host:** enemies, bosses, level state, loot rolls, run state. **Each client:** its own character's movement and attacks (predicted locally, validated by the host). |
| Level sync | Only the **seed + version** are sent; both players generate the same level locally |
| State sync | 20–30 Hz snapshots for enemies (interpolated on the guest); own player sent at 30 Hz |
| Hits | Attacker's machine detects hits on enemies → host validates (distance/timing sanity check) → result replicated |
| Parry and deflect under lag | **Favor the defender** within a small window (up to ~120 ms): if the guest parried "in time" on their screen, the host accepts it |
| Hit freeze and slow-mo | Hit freeze is **local only**. Focus (slow-mo) in co-op slows **only enemies near the user** and briefly, so the partner isn't slowed. |
| Bandwidth target | < 30 KB/s per player |
| Latency target | Feels good up to ~120 ms; playable up to ~200 ms |

### 28.2 Services

| Need | Service |
|---|---|
| Cross-platform accounts | **EOS Connect:** device-based login (no account needed) + optional linking with Steam/Apple/Google |
| Lobbies, room codes, invites | **EOS Lobbies** (+ Steam overlay invites for Steam players) |
| Peer-to-peer connection + relay | **EOS P2P** (NAT traversal with relay fallback), used through an EOS plugin's `MultiplayerPeer` (e.g. the community **EOSG** GDExtension; **verify in M0**) |
| Leaderboards and stats | **EOS Leaderboards/Stats** (cross-platform); achievements via Steam, Game Center, Play Games |
| Local/dev testing | Godot `ENetMultiplayerPeer` on LAN (same game code, different transport) |
| Reports and sanctions (if needed) | EOS Reports/Sanctions (no chat, so minimal) |

> If the EOS plugin isn't reliable enough on all platforms in M0, the fallback is: Steam networking
> (GodotSteam) for Steam players during EA, plus a small relay service for cross-play at 1.0. Decide in M0.

### 28.3 Robustness

- **Version check:** both players must run the same build; mismatch → friendly "please update".
- **Reconnect window:** 60 s (the game keeps the slot, the character goes idle and invulnerable).
- **Host leaves:** guest's run ends, all banked progress kept (host migration after 1.0).
- **Mobile backgrounding:** short app switches pause the local character (not the session); long ones disconnect cleanly.
- **Cheating:** co-op only, so the focus is leaderboards: submit seed + score + a compact action log; flag outliers.

### 28.4 Network testing

- Run 2 instances locally from day one (*Customize Run Instances*).
- Lag/packet-loss simulation (100–200 ms, 1–3% loss) for every combat change.
- Headless bot clients (`tools/net/`) for soak tests (2-hour sessions, many seeds).
- Weekly cross-device sessions: PC host + Android guest, Android host + iPhone guest, etc.

---

## 29. Procedural level generation

**Hybrid approach:** hand-made **room templates** combined by a generator following a hand-made
**area graph** (the method Dead Cells' developers have described publicly).

| Piece | Description |
|---|---|
| Room template | Scene with `TileMapLayer` + markers (doors, enemy spawns, Linked spawns, loot, hazards, lights) |
| Room types | Entrance, Exit, Combat, Corridor, Treasure, Forge, Shop, Bargain terminal, Hostage rescue, Elite arena, Challenge vault, Secret, Memory fragment |
| Area graph | e.g. `Entrance → Combat×3 → Hostage → Combat×2 → Shop → Combat×3 → Elite → Exit` with optional branches |
| Area data | Tileset, palette/lighting, enemy pools + weights, Linked ratio, loot table, density, music |

**Rules:** chunks of 24×16 tiles (rooms 1×1 to 4×3 chunks); doors at fixed chunk-edge positions;
every room passable with base movement (abilities only gate optional routes); 30–45 templates per area
(+ horizontal flips); co-op-friendly room sizes (no single-file tunnels longer than 2 chunks).

**Generator steps:** seed → expand graph → pick templates → place on chunk grid (backtracking) →
connect doors → spend enemy budget (Threat Level + co-op scaling) → place loot/events → validate →
build scene + minimap.

**Requirements:** < 300 ms on a low-end phone · 10,000-seed fuzz test per area with 0 failures ·
same seed + version = identical level on every platform (required for co-op and daily runs).

### 29.1 Multi-level (vertical) layout

Levels are never flat corridors. Like Dead Cells, every area stacks **3–5 levels** of play
connected in both directions, so players constantly jump up, drop down and choose routes.

**Connectors between levels**

| Connector | How it works | Notes |
|---|---|---|
| **One-way platforms** | Jump up through them; Down + Jump drops through | The main "stairs": stacks ≤ 5 tiles apart |
| **Drop-through floors** | A one-way section inside a floor | Lets players drop into the level below and jump back up |
| **Open drops** | Gaps at floor edges | Every drop has a visible landing and a way back up (or is a deliberate one-way shortcut) |
| **Wall-jump shafts** | Vertical shafts 4–6 tiles wide | Fast vertical routes; reward skill |
| **Ledges** | Wall tops the player can grab and climb | Forgives jumps that come up a little short |
| **Slam drops** | Down + Slash in the air dives onto enemies below | Makes dropping down an attack, not just movement |
| **Later: grapple points, breach walls, mag-ceilings** | Traversal unlocks (section 4) | Open secret routes between levels |

**Reach limits (Ronin tuning; 1 tile = 16 px)**

| Move | Height | Design rule |
|---|---|---|
| Jump | 80 px = 5 tiles | Platforms reachable by a single jump: ≤ 5 tiles above |
| Jump + double jump | ~140 px ≈ 8 tiles | Optional/skill routes: 6–8 tiles above |
| Horizontal gap (full run + jump) | ~8 tiles | Required gaps ≤ 6 tiles |
| Fall | Unlimited, no fall damage | Camera looks down while falling fast so landings are visible |

**Layout rules**
- Every room uses at least 2 levels; tall rooms (1 chunk wide × 2–3 chunks high) appear in every area.
- Place enemies on different levels: shooters on high perches, melee enemies below, so players choose an approach angle.
- Offer a **safe route and a risky route** (e.g. a spike pit with treasure vs a longer climb).
- No blind drops: a drop's landing must be visible (camera look-down) or telegraphed (light, debris).
- The way back up must exist within the same room unless the drop is a marked shortcut.
- Generator validation (step 8) checks reachability with these reach limits, both up and down.

**Gray-box sandbox:** `game/arena/maps/sandbox.txt` is a hand-made multi-level test map
(ASCII legend in `game/arena/test_arena.gd`) with every connector above, used to tune movement
and combat until real room templates exist.

---

## 30. Art pipeline: free and AI-assisted

**Budget for art: $0.** Everything is made on the Mac with free tools. AI makes what it's good at
(concepts, backgrounds, props, icons, illustrations); 3D and code make what must stay consistent
(animated characters, enemies, tiles, effects). Claude writes the scripts that connect the steps.

### 30.1 Free tools

| Tool | Use | Cost |
|---|---|---|
| **Draw Things** (Mac App Store) | Runs AI image models **locally** on the M4 Pro: no per-image fees, no account | Free |
| AI image models: **SDXL** (+ pixel-art LoRAs) or **FLUX.1 [schnell]** | Image generation. Only use models whose license allows commercial use of outputs; check each LoRA's license too | Free |
| **Blender** (installed) | 3D-to-pixel characters and enemies | Free |
| **Mixamo** (free Adobe account) | Auto-rigging + animation library (runs, jumps, sword attacks), royalty-free in games | Free |
| **LibreSprite** or **Pixelorama** | Pixel cleanup and touch-ups | Free |
| **Laigter** | Normal maps for 2D sprites (lighting) | Free |
| `tools/art/pixelize.py` (Claude) | Turns any AI image into LAST EDGE pixel art: downscale, snap to the game palette, clean edges | Free |
| `tools/blender/*.py` (Claude) | Procedural models (robots, drones, blades) + sprite rendering | Free |
| Free OFL pixel fonts (e.g. Silkscreen, Pixelify Sans) | UI text | Free |

### 30.2 How each kind of art is made

| Asset | Method |
|---|---|
| **Playable characters + humanoid enemies + the Linked** | AI concept turnaround (front/side) → body from a Mixamo base character, with coats, masks and gear built in Blender (simple shapes scripted by Claude) → Mixamo rig + animations → `render_sprites.py` → pixel sprite sheets + normal maps → cleanup |
| **Robots, drones, mechs, bosses** | Procedural low-poly models scripted in Blender (mechanical shapes suit code) → keyframed by script → rendered to pixels |
| **Blades** | Modeled by script; rendered as separate layers so any character can hold any blade |
| **Tilesets** | Generated in code by Claude (16×16, palette-based, Godot terrain/autotile sets), with AI texture detail run through `pixelize.py` |
| **Backgrounds (3–5 parallax layers per area)** | AI at high resolution → split into layers → `pixelize.py` |
| **Props and decoration** | AI → background removed → `pixelize.py` |
| **Item and blade icons (~200)** | AI → `pixelize.py` at 32×32 with the game palette |
| **VFX** | Code: Godot particles and shaders, procedural slash smears |
| **UI** | Code (9-slice panels) + pixel fonts + AI icons |
| **Story illustrations, Steam capsules, key art** | AI at high resolution + cleanup; the most visible marketing images, so allow the most iteration |

**Never animate characters with image AI frame by frame**: it can't keep a character consistent
between frames. Animation always comes from 3D (Mixamo/Blender), so every frame matches.

**Done so far:** the game palette (`tools/art/palette.gpl`), `pixelize.py`, the sandbox's
tileset and rain (`generate_sandbox_art.py`), and a 3-layer AI parallax backdrop: Stable
Diffusion XL running locally (`generate_ai_backgrounds.py`), then cut out, made seamless,
darkened by depth and pixelized (`process_backgrounds.py`).

### 30.3 3D-to-pixel rendering

```
Blender: model + rig + animation (toon/flat shading, limited colors per material)
 → tools/blender/render_sprites.py
     • orthographic side camera, fixed pixel scale (hero ≈ 48–56 px tall)
     • low-res render, no anti-aliasing
     • passes: color + normal map (+ emission for neon/implants)
     • every animation, right-facing only (Godot flips for left)
     • frame timings exported to match the combat frame data (section 5.4)
 → sprite sheets + metadata → Godot import script → SpriteFrames / AnimationPlayer
 → cleanup in LibreSprite/Pixelorama (faces, sword smears, highlights)
```

- One rig per body type; characters and Linked variants reuse rigs.
- **Co-op alternate colors** via a palette-swap shader (no extra renders).

### 30.4 Consistency rules

- One palette for the whole game: `tools/art/palette.gpl` (cold teal/white, warm amber/red). Every image passes through `pixelize.py` so all art shares the palette and pixel size.
- One style prompt file: `tools/art/style_prompts.md` with the shared prompt prefix per asset type, plus the seeds of approved images.
- Generate many, keep few. Approve against the mood board before anything goes into the game.
- Expect cleanup: plan roughly a third of art time for fixing AI output by hand or with scripts.
- **Checkpoint:** the vertical slice (M6) decides whether the look is good enough. If one piece falls short (usually key art), that's the only place to reconsider spending.

### 30.5 Legal for AI art

- Log every AI-generated asset in `ASSET_LICENSES.md`: tool, model, prompt, date.
- **Steam requires disclosing AI-generated content** (store page questionnaire).
- AI images generally can't be copyright-protected (e.g. in the US), so others could reuse the art.
  The game as a whole (code, story, characters, design) is still yours.
- Mixamo assets are royalty-free inside games but can't be redistributed as raw files.

---

## 31. Save data and cross-progression

- Files in `user://`: `profile.json`, `run.json`, `settings.cfg`; atomic writes + backup; `save_version` migrations.
- **Mid-run save** at every Forge and when the app closes; resumes at the start of the current area (solo).
  Co-op runs resume solo for the host if the partner is gone.
- **Cloud:** Steam Cloud (EA). At 1.0: **cross-progression** via EOS Player Data Storage, so progress follows the
  player between PC and phone after linking accounts (stretch goal; platform clouds as the fallback).

```json
{
  "save_version": 1,
  "memory_shards": 0,
  "characters": ["ronin", "breaker"],
  "unlocked": { "blades": ["katana", "nodachi", "twin"], "gadgets": ["smoke", "emp"], "techniques": ["deflect_burst"] },
  "mastery": { "katana": { "level": 3, "xp": 412 } },
  "evolutions_found": ["stormcutter"],
  "mercy": { "freed_total": 87, "executed_total": 12 },
  "threat_level_unlocked": 2,
  "hub_stage": 3,
  "story_flags": ["act2_unlocked", "met_unit_seven"],
  "endings": [],
  "stats": { "runs": 41, "wins": 2, "best_daily": 18420 }
}
```

---

## 32. Performance budgets

| Item | Target |
|---|---|
| Frame rate | 60 fps on mid-range phones, Steam Deck and PC; 30 fps fallback on low-end phones |
| Active enemies | ≤ 14 (co-op ≤ 18); off-screen enemies sleep |
| 2D lights | ≤ 8 visible; ≤ 3 lights per sprite |
| Particles | Pooled, capped; "Low effects" option |
| Generation + load | ≤ 3 s on a low-end phone |
| Memory | ≤ 800 MB on low-end phones |
| Install size | ≤ 250 MB on mobile |
| Network | < 30 KB/s per player; no frame drops on packet bursts |

Profile on the low-end phone at the **end of every milestone** (Godot profiler, remote debugger, Android GPU Inspector, Xcode Instruments).

---

## 33. Analytics, crash reporting and privacy

| Need | Tool |
|---|---|
| Crash reports | A crash SDK with Godot support (e.g. Sentry), with consent |
| Gameplay telemetry | Opt-in events to EOS Stats or a lightweight endpoint |
| Key events | `run_start`, `area_enter`, `run_end` (cause, area, build), `blade_pick`, `forge_action`, `bargain`, `linked_choice`, `boss_attempt/kill`, `coop_session` (latency, disconnects) |
| Balance | Pick/win rates per blade, technique and character; death causes per area; Mercy rates |

**Privacy:** no personal data in events; consent where required; privacy policy (simple website); Apple App Privacy and
Google Data safety forms must reflect EOS, crash reporting and telemetry. Online play → declare user interaction
in age ratings where asked (no chat reduces requirements).

---

## 34. Testing strategy

| Type | What | When |
|---|---|---|
| Unit tests (`tests/run_tests.gd`) | Damage, posture, Resolve, Flow, forge math, evolution recipes, saves | Every change |
| Generator fuzz | 10,000 seeds per area; validity + time | Every generator/room change |
| Cross-platform determinism | Same seed → same level hash on Windows, Android, iOS | Weekly |
| Network tests | Lag/loss simulation, bot soak tests, reconnect, version mismatch | Every combat/net change; nightly soak |
| Scripted playtests | Recorded inputs replayed headless (Movie Maker mode) | Nightly |
| Feel tests | 3–5 people, solo and co-op, without help | M1, M2, M6, each EA update |
| Device matrix | Low/mid Android, 2 iPhones, Steam Deck, PC | Every milestone |
| Betas | Steam Playtest; Google closed test (12+ × 14 days); TestFlight | M7, M11 |

**CI (GitHub Actions):** tests + fuzz + Windows/Linux/Android exports on every push to `main`.
**In-game "Report bug"** copies version, seed, platform and co-op session info.

---

# Part 3: Production

## 35. Content targets

| Content | Demo | Early Access | 1.0 |
|---|---|---|---|
| Characters | 1 | 3 | 5 |
| Areas | 2 | 5 | 8 + secret |
| Bosses | 1 | 2 | 4 |
| Blades | 3 | 8 | 15 |
| Mastery tracks | 3 | 8 | 15 (×5 levels) |
| Evolutions | 1 | 4 | 10 |
| Physical mods | 6 | 15 | 30 |
| Smart mods | 2 | 6 | 12 |
| Gadgets | 4 | 10 | 20 |
| Techniques | 8 | 20 | 40 |
| Charms | 4 | 15 | 30 |
| Traits | 8 | 20 | 40 |
| Bargains | 4 | 12 | 25 |
| Enemies (incl. Linked) | 8 | 16 | 28 |
| Threat Levels | — | 1–3 | 1–10 |
| Endings | — | — | 3 |
| Co-op | Steam ↔ Steam | Steam ↔ Steam | Cross-play everywhere |
| Daily/weekly runs | — | ✅ | ✅ |

---

## 36. Milestones with task checklists

### M0 — Setup, pre-production and tech spikes · ~3 weeks

- [x] Tools installed on the Mac (Godot 4.7.2, Git LFS, GitHub CLI)
- [ ] Tools installed on the Windows PC (section 22)
- [x] Repo files: `.gitignore`/`.gitattributes` + `PLAN.md`, `AGENTS.md`, `CLAUDE.md`, `ASSET_LICENSES.md`
- [ ] Private GitHub repository + first push
- [x] Project settings (section 26) via `dev/configure_project.gd`
- [ ] Renderer test on the low-end phone
- [x] Project runs on the Mac
- [ ] Runs on Windows, Android and iPhone
- [x] Unit test runner (`tests/run_tests.gd`)
- [ ] CI (tests + exports)
- [ ] **Net spike 1:** two local instances connect with ENet; a moving square syncs
- [ ] **Net spike 2:** EOS plugin login + lobby + P2P relay between **PC ↔ Android** (and iOS if possible) → decide EOS vs fallback
- [ ] Name check: LAST EDGE, HALCYON, characters (Steam, stores, USPTO/WIPO)
- [ ] One-page design summary + mood board (cold/warm color script)
- [ ] AI concept pass (local, free): the Ronin, 2 machines, 1 Linked, Neon Slums mood

**✅ Exit:** builds on every platform; two devices connect through EOS (or the fallback is chosen).

### M1 — Networked combat feel prototype · ~5–6 weeks

- [x] Ronin offline movement: run, variable jump, double jump, coyote time, jump buffer, wall slide/jump, drop-through, dodge with i-frames
- [x] Ledge grab
- [ ] Player movement **networked with prediction**
- [ ] Input actions + controller + keyboard/mouse + **touch v1**
- [ ] Components: Resolve, posture, hitbox/hurtbox, knockback; damage pipeline v1
- [x] Katana slash combo (3 hits, 8 directions, frame data)
- [x] Deflect, parry, quick-draw, executions
- [x] Focus slow-mo (solo version)
- [ ] Focus co-op local-area version
- [x] Feedback: hit freeze, flash, screen shake
- [ ] Kill freeze-frame, sounds, particles
- [x] Enemies: Patrol Drone (deflect), Hound (parry)
- [x] Enemy: Linked Citizen (cut the link → freed; Mercy record saved in the profile)
- [x] Multi-level gray-box sandbox (ASCII map), follow camera with fall look-down, training dummy, spikes
- [x] Slam (Down + Slash in the air) with landing shockwave
- [x] First free art: code-generated tileset with auto-tiling, rain, `pixelize.py`
- [x] AI parallax backdrop (3 layers, local SDXL, $0)
- [x] Blender 3D-to-pixel pipeline; Hound and Patrol Drone as animated sprites
- [x] The Ronin (hero) built and posed in Blender: 21 animations synced to the frame data
- [x] Combat choreography (stepping combo hits, leaping finisher, attack magnetism, air hang time) and combo counter with ranks
- [x] Burning amber katana: longer blade, flames, swing fire, smoke, embers, firelight; fiery trails and hit fire bursts
- [x] Sound: 31 synthesized effects hooked to every action, "Neon Rain" music loop, rain ambience
- [x] Ninja movement: low leaning sprint (12 frames, speed-matched), crouched sneak, forward-roll dodge, double-jump front flip, scarf follow-through
- [x] Level art: building facades with windows/pipes/signs and alleys, floor props, foreground silhouettes
- [x] Lighting & atmosphere: dark ambient, lamp/neon/warning lights with light pools, normal-mapped characters, hero key light, fog, vignette, color grading
- [x] Dead Cells-style effects: glowing blade trails along the real blade, sparks, cut marks, hit lights, bloom, damage numbers, afterimages, dust, slam ring, enemy death bursts with oil
- [ ] Demo build (see MIXAMO_DOWNLOADS.md for the human characters): Warden boss, 2 areas with random rooms, blade pickups, title/end screens, sounds, web + Windows + Mac builds
- [ ] **2-player co-op on LAN** with lag simulation

**✅ Exit:** fighting feels great solo and in co-op at 150 ms simulated lag, on controller and on a phone.

### M2 — Combat depth · ~6 weeks

- [ ] Blade system data-driven (CSV → `.tres`): Katana, Nodachi, Twin Blades, Cleaver
- [ ] Flow meter; elements + status effects; Patch Kits
- [ ] Gadgets ×4 (smoke, EMP, caltrops, grapple)
- [ ] Techniques ×8, charms ×4
- [ ] Enemies: Sentry Turret, Riot Unit, Sniper Drone, Enforcer Android, Linked Officer, Linked Gunner; elites; attack tokens
- [ ] Co-op: revive, scaling, instanced loot, pings + emotes, Cross Cut
- [ ] Unit tests for combat math

**✅ Exit:** different blades feel distinct; mixed groups are fair; co-op adds real teamwork.

### M3 — Level generator · ~5–6 weeks

- [ ] Room template format + markers + editor workflow
- [ ] Area graph resource + generator + validators
- [ ] Enemy budget (Threat Level + co-op), loot + events placement
- [ ] Minimap + map screen; doors, area exits (both players required)
- [ ] 35 gray-box rooms for Neon Slums; 20 for Rain Rooftops
- [ ] Fuzz + cross-platform determinism tests; co-op seed sync

**✅ Exit:** every run (solo or co-op) generates a different, fully playable gray-box area.

### M4 — Run loop, upgrades and meta · ~6 weeks

- [ ] `RunState`, currencies, Forge (sharpen, temper, mods, reforge), memory terminals
- [ ] Blade mastery (3 tracks), first evolution (Stormcutter), 2 Smart mods + Attention/hijack
- [ ] Bargain terminals (4), volunteer traits (8)
- [ ] Undercroft hub v1: Smith, Archivist, Juno, unlock tree, Mercy counter
- [ ] Save system + migrations + suspend/resume
- [ ] The Warden (gray box), 3 phases
- [ ] Results screen; death → hub; win stub

**✅ Exit:** a complete gray-box loop in solo and co-op: hub → 2 areas → Warden → unlocks → next run.

### M5 — Online infrastructure · ~5 weeks

- [ ] EOS login (device), account linking (Steam), lobbies, room codes, Steam invites
- [ ] P2P through relay; reconnect window; version check; host-leaves handling
- [ ] Network bot soak tests; telemetry for latency/disconnects
- [ ] Cross-device test: PC ↔ Android ↔ iPhone (internal only; cross-play stays off for EA)
- [ ] Leaderboards backend (daily run prototype)

**✅ Exit:** two people anywhere can play a full gray-box run together reliably.

### M6 — Art pipeline and vertical slice · ~10 weeks · ⭐ decision point

- [ ] Ronin: final design → model/rig → Blender render script → import pipeline → all core animations
- [ ] Blade layer system (any character + any blade), palette-swap co-op colors
- [ ] Neon Slums + Rain Rooftops final art (tilesets, parallax, lighting, rain)
- [ ] 8 enemies + the Warden in final art; VFX pass (slashes, deflects, executions, cut the link)
- [ ] UI art: HUD, Forge, hub screens; fonts
- [ ] Music: Slums, Rooftops, Warden, hub; SFX pass
- [ ] Performance targets on low-end phone + Steam Deck
- [ ] **Steam page "Coming Soon"**: capsule art, screenshots, 60–90 s trailer (show co-op!)
- [ ] Devlog + social + Discord

**✅ Exit / decision:** a 15–20 minute slice (solo + co-op) that looks and plays like a real game. Show 10+ people,
check wishlists. **Decide:** continue, adjust scope/style, or simplify co-op.

### M7 — Steam demo and Next Fest · ~6 weeks

- [ ] Demo: Ronin, Slums + Rooftops, the Warden, 3 blades, co-op (Steam ↔ Steam)
- [ ] Steam achievements (demo), Steam Input, Steam Cloud, rich presence
- [ ] Steam Deck compatibility review
- [ ] Bug report button, crash reporting, opt-in telemetry
- [ ] Steam Playtest → fixes → public demo → **Steam Next Fest**

**✅ Exit:** public demo, stable co-op, growing wishlists.

### M8 — Early Access content · ~4–5 months

- [ ] EA content targets (section 35): Breaker, Ghost; Night Market, Maglev Line, Corporate Tower; the Mirror (adaptive AI)
- [ ] Mastery tracks for 8 blades; 4 evolutions; 6 Smart mods; 12 bargains; 20 traits
- [ ] Threat Levels 1–3; daily + weekly runs with leaderboards
- [ ] Hub growth stages 1–4; Act 1–2 story; memory fragments
- [ ] Accessibility + remapping complete
- [ ] Balance passes from playtest data
- [ ] EA store text + roadmap

**✅ Exit:** a satisfying 10–20 hour Early Access game, solo and co-op.

### M9 — Early Access launch · ~4 weeks

- [ ] Release candidate on Windows, Linux, Steam Deck; no known crashes; co-op stable
- [ ] Final trailer, screenshots, tags, price ($14.99), launch discount
- [ ] Press kit; streamer and creator outreach (co-op is great for streams)
- [ ] Day 1–14 hotfix plan

**✅ Exit:** live in Early Access. 🎉

### M10 — Early Access updates → 1.0 content · ~7–9 months

- [ ] Updates every 6–8 weeks (each with an area or boss + blades + techniques)
- [ ] Server Farms, Blackout District, the Core, the Old Net; the Matriarch; HALCYON
- [ ] Unit Seven + Doc Imari
- [ ] All 1.0 counts (section 35); Threat Levels 1–10; Act 3; all 3 endings
- [ ] Localization (8 languages + CJK font)
- [ ] Cross-progression (stretch)

### M11 — Mobile edition + cross-play · ~4 months (overlaps M10)

- [ ] Touch controls final, assists, UI scaling, safe areas
- [ ] Low-end phone performance; 30-minute heat/battery test
- [ ] Mobile co-op: backgrounding, reconnect, cellular networks
- [ ] **Cross-play on:** Steam ↔ Android ↔ iOS through EOS; same-day release process for updates
- [ ] Game Center + Play Games achievements; mobile leaderboards via EOS
- [ ] Google closed test (12+ × 14 days); TestFlight; store pages, ratings, privacy forms
- [ ] Paid-app setup on both stores ($9.99)

**✅ Exit:** mobile builds approved, cross-play verified on all platform pairs.

### M12 — 1.0 launch · ~4 weeks

- [ ] Steam 1.0 (price → $19.99) + Google Play + App Store on the same day
- [ ] Launch trailer, press, creator outreach, Steam launch discount
- [ ] Post-launch patch plan

**✅ Exit:** LAST EDGE 1.0 live everywhere, with cross-play. 🎉

---

## 37. Timeline

Assuming you work on it most days, with Claude writing the code:

```
Month:  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27
M0      █
M1      ██
M2        ██
M3          ██
M4            ██
M5              ██
M6               █████
M7                    ███
M8                       ██████████
M9                                 ██
M10                                  ██████████████████
M11                                           ██████████
M12                                                     ███
```

| Point | Month (approx.) |
|---|---|
| Vertical slice | ~11 |
| Steam demo / Next Fest | ~12–13 |
| **Early Access** | **~17–19** |
| **1.0 + mobile + cross-play** | **~25–28** |

Co-op with cross-play adds about 6–8 months compared with single-player. Art is the other main risk:
**start AI concepts and the free art tools early** and **build the 3D-to-pixel pipeline in M3–M4**.

---

## 38. Budget

**Art is $0** (section 30). Remaining costs are store fees and optional items.

| Item | Low | High |
|---|---|---|
| Steam Direct (game + demo is free) | $100 | $100 |
| Google Play + Apple (year 1) | $124 | $124 |
| All art: characters, enemies, areas, icons, UI, VFX, illustrations, key art (AI + free tools) | $0 | $0 |
| Music (free: CC0 tracks / own compositions; paid: composer) | $0 | $10,000 |
| SFX (free: sfxr/jsfxr + CC0 libraries) | $0 | $1,000 |
| Trailers | $0 (DIY) | $0 |
| Localization (8 languages; free: AI translation + community review) | $0 | $8,000 |
| Test devices (Android low-end, older iPhone, Steam Deck) | $0 (own devices) | $1,000 |
| Online services (EOS) | $0 | $0 |
| Trademark (optional) | $0 | $1,500 |
| **Total** | **~$224** | **~$21,700** |

The low column is a fully free production except store fees. Early Access revenue can fund any
optional items later.

---

## 39. Release strategy and pricing

| Phase | Platforms | Co-op | Price |
|---|---|---|---|
| Free demo (Next Fest) | Steam | Steam ↔ Steam | Free |
| Early Access | Steam (Windows, Linux/Deck) | Steam ↔ Steam | **$14.99** |
| 1.0 | Steam + Google Play + App Store | **Cross-play everywhere** | **$19.99** Steam, **$9.99** mobile |
| After 1.0 | All | All | Paid expansions (new act/characters) + optional cosmetic packs; free content updates |

- **No ads, no energy timers, no loot boxes, no pay-to-win.**
- Mobile version is premium (pay once). Cross-play between paid versions on all platforms.
- Updates must ship on all platforms on the same day (cross-play needs matching versions): submit mobile builds early, release together.

---

## 40. Store release checklists

### 40.1 Steam

- [ ] Steamworks account, app fee, tax/bank info (≈30 days after paying before release is allowed)
- [ ] "Coming Soon" page as early as possible (required ≥ 2 weeks before release)
- [ ] Capsules: header 920×430, small 462×174, main 1232×706, vertical 748×896, library 600×900, library hero 3840×1240, logo; ≥ 5 screenshots; trailer
- [ ] Tags: Action Roguelike, Roguelite, Hack and Slash, Online Co-Op, Cyberpunk, Pixel Graphics, 2D Platformer, Difficult
- [ ] AI-generated content disclosure (if any)
- [ ] SteamPipe depots (Windows + Linux); demo app for Next Fest
- [ ] Achievements, Steam Cloud, Steam Input, rich presence, invites
- [ ] Steam Deck review; Early Access questionnaire
- [ ] Valve build/store review before release

### 40.2 Google Play

- [ ] Account verified; payments profile (paid app); app created; package name final
- [ ] AAB (ARM64), required target API; Play App Signing; upload keystore backed up
- [ ] Listing text, icon 512×512, feature graphic 1024×500, screenshots, trailer
- [ ] IARC content rating (declare online interaction), Data safety (EOS, crash SDK), privacy policy URL
- [ ] Play Games Services (achievements)
- [ ] Internal → **closed test (12+ testers, 14+ days)** → production access → staged rollout

### 40.3 Apple App Store

- [ ] Developer Program; Paid Apps agreement + tax/banking; bundle ID; App Store Connect record
- [ ] Built with the required Xcode/SDK; distribution signing
- [ ] TestFlight internal → external
- [ ] App Privacy (EOS, crash SDK), age rating, encryption compliance (standard HTTPS → exempt)
- [ ] Sign-in rules: if any third-party/social login is offered on iOS, Apple's login requirements apply (device login avoids this)
- [ ] Game Center (achievements); controller support declared
- [ ] Screenshots (6.9"/6.5" iPhone, 13" iPad if supported), preview video
- [ ] Review notes explaining online co-op (provide a way for reviewers to test)

---

## 41. Legal and IP

- **Original everything:** no names, characters, story, art, music or UI from Katana ZERO, Dead Cells or any other game. Genre mechanics are fine.
- **No reverse engineering** of other games for this project (that includes REA). Learn from published talks and articles and your own play recordings.
- **Name checks** for LAST EDGE, HALCYON and character names before committing; consider a trademark after the slice.
- **Asset licenses** logged in `ASSET_LICENSES.md`; check fonts and music for commercial use.
- **Contracts** for all commissioned work, transferring full commercial rights.
- **AI-generated assets:** log them (tool, model, prompt); Steam requires disclosure; use only models whose licenses allow commercial use; see section 30.5.
- **Third-party terms:** EOS, Steamworks, Apple and Google developer agreements; open-source notices (Godot MIT, plugins) in the credits.
- **Sensitive theme:** AI and implants are fictional; avoid real companies, products or people.
- **Business:** consider registering a business before EA (store organization accounts, payouts, taxes).

---

## 42. Risks and mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **Co-op netcode makes combat feel worse** | High | Very high | Networked from M1; prediction + favor-the-defender; lag simulation on every change; local-only hit freeze |
| **Cross-play complexity (EOS plugin, mobile)** | High | High | Spike in M0; EA ships Steam-only co-op; cross-play gated to 1.0; fallback plan (section 28.2) |
| Combat doesn't feel great | Medium | Very high | Feel-first M1 with real players; data-driven tuning |
| Scope too big (5 characters, 15 blades, co-op) | High | High | Staged content (section 35); M6 decision; cut list (e.g. Zanbato, Old Net, cross-progression) |
| Art cost/speed | High | High | 3D-to-pixel pipeline, shared rigs, blade layers, palette swaps; early concept art |
| Mobile performance + co-op on cellular | Medium | Medium | Budgets, low-end phone testing, reconnect window |
| Same-day updates across 3 stores | Medium | Medium | Version gating; submit mobile builds early; staged release |
| Visibility | High | High | Steam page at M6, devlogs, Next Fest demo with co-op, creators |
| Balance (characters × blades × techniques) | High | Medium | Telemetry, EA community, data-driven tuning |
| Losing keys/work | Low | Very high | GitHub + LFS, daily commits, keys backed up twice |
| IP complaint | Low | High | Original content, name checks |
| Burnout over ~2+ years | Medium | High | Playable result every milestone; realistic weekly goals; community support |

---

## 43. Research and references

Study these for the lessons, not the content:

- **Combat feel:** GDC talks on game feel / "juice", hit stop and enemy telegraphing; frame-by-frame study of your own recordings of action games you own.
- **Level generation:** Dead Cells' developers' write-ups on their hybrid procedural level design; Spelunky's level generation articles.
- **Art pipeline:** Dead Cells' developers' write-up on using a 3D pipeline for 2D pixel animation.
- **Netcode:** articles on client-side prediction, entity interpolation and lag compensation (e.g. Gabriel Gambetta's
  "Fast-Paced Multiplayer" series; "Gaffer On Games" networking articles); GDC talks on networked action games.
- **Godot docs:** high-level multiplayer, `MultiplayerSynchronizer` / `MultiplayerSpawner`, 2D lights, TileMapLayer,
  exporting for Android/iOS, command-line usage, Movie Maker mode.
- **EOS docs:** Connect interface, Lobbies, P2P, Leaderboards/Stats, Player Data Storage.

---

## 44. Immediate next steps

1. **Windows PC:** install Godot 4 (+ export templates), Git + LFS, OpenJDK 17 + Android SDK, Blender, Aseprite, Claude Code.
2. **Copy `PLAN.md`** (and `PLAN-unity-3d-platformer.md`) to `C:\Dev\LastEdge`.
3. **Create an Epic Online Services developer account** (free) for the M0 network spike.
4. **Install Draw Things** (free, Mac App Store) for local AI concepts: the Ronin, 2 machines, 1 Linked, Neon Slums mood, cold/warm palette.
5. Open Claude Code in `C:\Dev\LastEdge` and say: *"Start M0 from PLAN.md."*
