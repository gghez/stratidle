# Agent Instructions — Stratidle

## Project Overview

Stratidle is a 2D idle/strategy tower defense game built with Godot 4.6.1. The player defends a desert base from waves of alien invaders across 11 levels (10 waves each). The game features three weapon arsenals, irreversible upgrades, and a local leaderboard.

## Environment

- Engine: **Godot 4.6.1**
- Define the Godot console executable in a local `.env` file ignored by Git:
  ```
  GODOT_CONSOLE_EXE='<local path to the Godot console executable>'
  ```
- From WSL, run headless verification from the project root with:
  ```
  source .env && "$GODOT_CONSOLE_EXE" --headless --path './' --quit
  ```
- The Godot IDE on Windows is reloaded manually after changes.

## Project Structure

```
scripts/
  main.gd              — Root controller (state machine, lifecycle, rendering)
  enemy.gd             — Static utility: enemy stat templates and building
  enemy_entity.gd      — Node2D entity for enemy instances
  projectile_entity.gd — Node2D entity for projectiles (player + enemy)
  explosion_entity.gd  — Node2D entity for explosion animations
  wave_manager.gd      — Static utility: deterministic wave generation
  leaderboard.gd       — Static utility: JSON leaderboard persistence
scenes/
  main/main.tscn       — Main scene with HUD hierarchy
assets/
  sprites/             — SVG/PNG game sprites
  effects/             — Explosion animation frames
  audio/               — OGG/WAV sound effects and music
```

## Coding Conventions for GDScript (Godot 4)

### Type System — ALWAYS Use Types

```gdscript
# GOOD
var speed: float = 42.0
var enemies: Array[EnemyEntity] = []
func apply_damage(amount: float) -> bool:

# BAD — never do this
var speed = 42.0
var enemies = []
func apply_damage(amount):
```

- Every `var` declaration must have a type annotation (`: Type` or `:= value` for inference).
- Every function must declare return type (`-> void`, `-> bool`, `-> float`, etc.).
- Every function parameter must have a type annotation.
- Use `Array[Type]` for typed arrays, never raw `Array`.
- Use `class_name` on all new scripts that will be referenced from other scripts.

### Prefer Typed Classes Over Dictionaries

```gdscript
# GOOD — typed, autocomplete-friendly, compile-time checked
class_name Arsenal extends RefCounted
var damage: float = 0.0
var fire_rate: float = 0.0

# BAD — fragile, no autocomplete, runtime errors
var arsenal: Dictionary = {"damage": 0.0, "fire_rate": 0.0}
```

- Use `RefCounted` classes for data objects (no scene tree presence needed).
- Use `Node2D` classes for entities that need rendering (`_draw()`) or scene tree position.
- Only use `Dictionary` for serialization (JSON load/save) or truly dynamic key-value data.
- When converting dict-based code, create a typed class and migrate callers.

### Enums Over String Constants

```gdscript
# GOOD
enum GameState { IDLE, FIGHTING, UPGRADE, GAME_OVER, VICTORY }
var state: GameState = GameState.IDLE

# BAD
const STATE_IDLE := "idle"
var state := STATE_IDLE
```

- Define enums in a shared `class_name GameEnums` script or at the top of the script that owns them.
- Use enums for: game states, entity types, arsenal IDs, projectile kinds, upgrade kinds.
- Keep string labels only for UI display (French text), never for logic.

### Named Constants Over Magic Numbers

```gdscript
# GOOD
const COLLISION_DISTANCE := 18.0
if position.distance_to(enemy.global_position) <= COLLISION_DISTANCE:

# BAD
if position.distance_to(enemy.global_position) <= 18.0:
```

- Extract any gameplay-relevant number into a `const` at the top of the file.
- Pixel positions for rendering (dune polygon points, UI layout) are acceptable as literals.
- Group constants logically: game rules, physics, audio, visual.

### File Organization

- One responsibility per script. Keep scripts under 300 lines.
- Static utility classes extend `RefCounted` and use `static func`.
- Entity classes extend `Node2D` and own their `_draw()` method.
- Controller scripts extend `Node` and are attached to scene tree nodes.
- Name files in `snake_case.gd` matching the `class_name` in `PascalCase`.

### Signals for Communication

```gdscript
# Define in the emitter
signal enemy_destroyed(enemy: EnemyEntity)

# Connect in the receiver
combat.enemy_destroyed.connect(_on_enemy_destroyed)
```

- Use signals when two separate scripts need to communicate.
- Do NOT use signals for intra-script method calls.
- Prefer `signal` over direct method references across scripts.

### Node Management

- Create runtime nodes via code (`Node.new()` + `add_child()`), not preloaded scenes, for simple entities.
- Always call `queue_free()` when removing nodes — never `free()`.
- Use `is_instance_valid(node)` before accessing nodes that might have been freed.
- Prefer `@onready var` for scene tree references.

### Rendering

- Each entity draws itself in its own `_draw()` method.
- The root script (`main.gd`) draws only static background elements (desert, base, health bars).
- Call `queue_redraw()` after any state change that affects visuals.
- Never duplicate drawing logic across files — extract shared rendering into a utility function.

### Audio

- Use `AudioStreamPlayer` with `max_polyphony` for concurrent sounds.
- Store base volume as metadata: `player.set_meta("base_volume_db", volume)`.
- Check audio bus existence before assignment.
- Loop music via the `finished` signal, not `AudioStream.loop` (more control).

### Error Handling

- Validate file I/O results: check `error == OK` after `load()`, `save_png()`, etc.
- Use `push_warning()` for recoverable issues, `push_error()` for critical failures.
- Never silently swallow errors.

### Language

- All code comments, symbol names (variables, functions, classes, enums), documentation, commit messages, and GitHub issues/PRs must be written in **English**.
- French is only used for in-game UI display text (labels, tooltips, dialogues).

## Workflow

1. **Before any change**: read `README.md` to verify current game rules (once per session).
2. **After changes**: run headless verification:
   ```
   source .env && "$GODOT_CONSOLE_EXE" --headless --path './' --quit
   ```
3. **Keep README.md updated**: if a change modifies game rules or structure, update the relevant section.
4. **Keep improvement.md updated**: after completing an improvement task, mark it done or remove it.
5. **One commit per priority/task**: do not bundle unrelated changes.

## What NOT to Do

- Do NOT introduce new dependencies or plugins.
- Do NOT change game balance values unless explicitly requested.
- Do NOT refactor code that is not part of the current task.
- Do NOT create `.tscn` files when a script-only solution works.
- Do NOT use `await` in `_process()` or `_draw()`.
- Do NOT use `get_node()` with string paths in game logic — use `@onready var` references.
- Do NOT leave empty `pass` methods — delete them entirely.
- Do NOT duplicate logic across files — extract to a shared utility.

## Key Game Rules Reference

- 11 levels, 10 waves per level, 30 seconds per wave
- 3 arsenals: machine gun (starts at 1), missiles (starts at 0), EMP (starts at 0)
- Upgrades: count (+1, max 10), damage (+10% + projectile size/speed), fire rate (+20%)
- Enemies: saucer (rank 1), cruiser (rank 2), flagship (rank 3), boss (rank 5)
- HP scaling: base_hp * (1.0 + (level - 1) * 0.22)
- Dome: 1000 HP shield, House: 100 HP underneath
- Score: +1 per hit, +10 * rank per kill
- Leaderboard: sorted by completion time (ascending), 10 entries max
- Saucers can absorb camels (2x all stats), camels respawn each wave
- Waves are deterministic (same composition per level/wave, different spawn positions)
