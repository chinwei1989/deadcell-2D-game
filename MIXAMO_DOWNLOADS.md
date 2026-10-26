# Mixamo downloads for the demo

> **Update:** the Ronin is now built and animated in Blender by script
> (`tools/blender/models/ronin.py`), so section 1 is optional. Use it only if you want
> motion-captured movement for the hero later. Section 2 (Linked Citizen) is still useful.

The demo's human characters (the Ronin and the Linked Citizen) are animated with free
Mixamo animations, then rendered to pixel sprites in Blender by `tools/blender/`.
Mixamo needs a free Adobe account, so this part is yours. It takes about 30–45 minutes.

## Setup

1. Go to **mixamo.com** and sign in with a free Adobe account.
2. Create these folders in the project (if they don't exist):
   - `art/source/mixamo/ronin/`
   - `art/source/mixamo/linked/`

## Download settings (the same for every file)

| Setting | First file of each character | All other files |
|---|---|---|
| Format | FBX Binary (.fbx) | FBX Binary (.fbx) |
| Skin | **With Skin** | **Without Skin** |
| Frames per Second | 30 | 30 |
| Keyframe Reduction | none | none |

- Tick **In Place** whenever Mixamo shows that box (running, walking, jumping), so the
  character doesn't move away from the camera.
- **Rename each file** to the name in the "Save as" column.

## 1. The Ronin → `art/source/mixamo/ronin/`

**Character (Characters tab):** pick one that suits a hooded swordfighter, for example
search "ninja". If nothing fits, use **Y Bot**; I'll add the coat, mask and hood in Blender.
Download it **With Skin** with the "idle" animation below applied, saved as `idle.fbx`.

| Save as | Search Mixamo for | Notes |
|---|---|---|
| `idle.fbx` | sword idle (or "great sword idle") | With Skin (first file) |
| `run.fbx` | running (or "sword run") | In Place |
| `jump.fbx` | jump | In Place |
| `fall.fbx` | falling idle | |
| `land.fbx` | falling to landing | |
| `dodge.fbx` | stand to roll (or "sprinting forward roll") | In Place if offered |
| `slash1.fbx` | great sword slash (or "sword slash") | pick a horizontal swing |
| `slash2.fbx` | a different sword slash | a backhand / return swing |
| `slash3.fbx` | great sword high spin attack (or a big overhead slash) | the combo finisher |
| `guard.fbx` | great sword blocking (or "sword and shield block") | parry and guard pose |
| `draw.fbx` | draw a great sword (or a fast single slash) | used for the quick-draw strike |
| `slam.fbx` | great sword jump attack | the slam |
| `hurt.fbx` | sword and shield impact (or "hit reaction") | |
| `death.fbx` | dying (or "sword and shield death") | |
| `hang.fbx` | hanging idle | ledge grab |
| `climb.fbx` | braced hang to crouch (or "climbing to top") | ledge climb |

## 2. The Linked Citizen → `art/source/mixamo/linked/`

**Character:** any casual civilian (hoodie, jacket or work clothes). Download it
**With Skin** with the "idle" animation applied, saved as `idle.fbx`.

| Save as | Search Mixamo for | Notes |
|---|---|---|
| `idle.fbx` | zombie idle | With Skin (first file). Looks "controlled". |
| `walk.fbx` | zombie walk | In Place |
| `grab.fbx` | zombie attack | the grab |
| `hurt.fbx` | zombie reaction hit | |
| `stagger.fbx` | dizzy | posture broken |
| `freed.fbx` | terrified (or "walking" looking around) | after the link is cut |
| `death.fbx` | zombie dying | executed |

## When you're done

Tell Claude (or DeepSeek): **"Mixamo files are in art/source/mixamo"**. The render
script turns them into pixel sprites automatically.

## License notes

- Mixamo characters and animations are royalty-free to use **inside** your game, including
  commercially. You may not share the raw .fbx files publicly, so keep the repository private.
- Log them in `ASSET_LICENSES.md` (Claude will do it when importing).
