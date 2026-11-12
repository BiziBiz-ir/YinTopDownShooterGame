# New Game Project — Twin-Stick Shooter

Top-down arena shooter built with Godot 4.7. No external art: everything is vector polygons.

## Controls

| Action | Input |
| --- | --- |
| Pick a weapon (start screen) | Click a card, or `1`-`5`, `Enter` |
| Move | `WASD` / arrow keys |
| Aim | Mouse |
| Fire | Left click (or `Space`) |
| Restart | `R`, or the PLAY AGAIN button |
| Quit | QUIT button on the death menu |

## Weapons

All five are defined in one table at the bottom of `scripts/weapon.gd`.

| Weapon | Dmg | Rate | Notes |
| --- | --- | --- | --- |
| Handgun | 1 | 6.2/s | accurate baseline, no recoil to speak of |
| Pistol | 3 | 2.2/s | hand cannon, pierces 2 enemies, heavy kick |
| SMG | 1 | 14.3/s | huge rate, wide spread — close range only |
| Rifle | 2 | 7.1/s | fast and precise, pierces 2 enemies |
| Shotgun | 7 (1 × 7) | 1.5/s | pellet spread, dies off past ~250px |

Bullets carry their own damage, pierce count, lifetime and colour from the weapon.

Dying plays a CRT power-off effect (image collapses to a line, then a dot), ending on a
black screen where the death menu fades in — PLAY AGAIN / QUIT.

## Rules

- Waves of chasers spawn around the arena edge and come at you.
- From wave 2, **bombers** show up: faster, orange, six-sided. They rush you, prime
  with a flicker at close range, then detonate for 2 HP. Shooting one sets it off
  harmlessly, so kill them at range.
- 5 HP. Contact with an enemy costs 1 HP, then 0.9s of invulnerability.
- Enemy dies in 1 shot early on; from wave 5 they take 2 hits.
- Score: `10 + wave` per kill, plus a `25 × wave` clear bonus. Every 4th wave they get faster.

## Layout

```
project.godot          input map, 1280x720 window, main scene
scenes/main.tscn       arena, walls, containers, HUD
scenes/player.tscn     CharacterBody2D, layer 1, mask 4 (walls)
scenes/enemy.tscn      CharacterBody2D, layer 2, mask 4
scenes/bomber.tscn     kamikaze variant, same layers
scenes/explosion.tscn  blast visual (draws expanding ring, no collision)
scenes/bullet.tscn     Area2D, layer 8, mask 2 (enemies)
scripts/main.gd        wave spawning, score, game over, grid background
scripts/player.gd      movement, aim, shooting, damage, i-frames
scripts/enemy.gd       chase, separation, contact damage, death
scripts/bomber.gd      fast chase, fuse, blast damage
scripts/explosion.gd   blast ring animation
scripts/bullet.gd      travel and hit detection
scripts/weapon.gd      weapon data + catalogue (stats live here)
scripts/loadout_menu.gd  start screen weapon picker
scripts/hud.gd         score / wave / HP / weapon name / banner / death menu
scripts/crt_effect.gd  drives the CRT power-off shader
scripts/sfx.gd         `Sfx` autoload: 12-player pool, pitch variation
shaders/crt_off.gdshader  collapsing screen + scanlines
assets/sfx/*.wav       generated arcade SFX (see below)
tools/gen_sfx.py       synthesizes every sound; re-run after tweaking
tests/smoke.gd         headless assertions (shooting, damage, death, menu)
tests/shot.gd          renders frames to /tmp/opencode/*.png
```

Collision layers are deliberately minimal: player and enemies do **not** collide physically,
so enemies can crowd you without shoving you around; contact damage is distance-based.

## Sound

All SFX are synthesized by `tools/gen_sfx.py` — square/noise oscillators, one-pole filter
sweeps, bit-crush and sample-hold for grit. No third-party samples, nothing to attribute.

| Sound | Used for |
| --- | --- |
| `handgun`, `pistol`, `smg`, `rifle`, `shotgun` | firing; each weapon has its own voice |
| `explosion` | bomber detonation |
| `hurt` | non-fatal hit |
| `death` | player death, doubling as the CRT power-down whine |
| `select` | choosing a weapon |

Regenerate after editing timbres:

```bash
python3 tools/gen_sfx.py && ~/Downloads/Godot_v4.7.2-stable_linux.x86_64 --headless --import
```

Playback goes through the `Sfx` autoload (12 pooled `AudioStreamPlayer`s, ±5% pitch
variation so repeats don't machine-gun).

## Run

```bash
~/Downloads/Godot_v4.7.2-stable_linux.x86_64 -e --path .
```

Play without the editor:

```bash
~/Downloads/Godot_v4.7.2-stable_linux.x86_64 --path .
```

Headless checks:

```bash
~/Downloads/Godot_v4.7.2-stable_linux.x86_64 --headless --script res://tests/smoke.gd
```

## Obvious next steps

- Muzzle flash, hit sparks, death particles (CPUParticles2D).
- Music: a looping chiptune bassline via `AudioStreamPlayer` on its own bus.
- A screen shake via `Camera2D` on the player.
- Enemy variety: a slow brute with 5 HP, a shooter that fires back.
- High score persistence with a `ConfigFile` in `user://`.
