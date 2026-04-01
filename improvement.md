# Stratidle — Improvement Plan for Codex

This document is designed for Codex CLI (GPT-5.4) to execute. Each section is a self-contained task with Goal, Context, Constraints, and Done criteria.

---

## Priority 1 — Type Safety: Replace Raw Dictionaries with Typed Classes [DONE]

### Goal

Replace all `Dictionary` usage for game entities (arsenals, camels, wave data) with proper GDScript classes. The codebase uses typed `Node2D` entities for enemies, projectiles, and explosions, but arsenals, camels, and wave data are still raw dictionaries. This makes the code fragile, hard to refactor, and loses GDScript's type system.

### Context

- `scripts/main.gd`: arsenals are `Dictionary` (line ~124), camels are `Array[Dictionary]` (line ~116), `current_wave_data` is `Dictionary` (line ~114)
- `scripts/enemy.gd`: `build_enemy()` returns a `Dictionary` that gets fed into `EnemyEntity.setup(data: Dictionary)` — this intermediate dict is unnecessary
- `scripts/wave_manager.gd`: `build_wave_data()` returns a `Dictionary`
- Pattern to follow: `enemy_entity.gd`, `projectile_entity.gd`, `explosion_entity.gd` already use typed properties

### Tasks

1. **Create `scripts/arsenal.gd`** — a `RefCounted` class with typed properties:
   - `id: String`, `title: String`, `count: int`, `max_count: int`
   - `damage: float`, `damage_level: int`, `fire_rate: float`, `fire_rate_level: int`
   - `projectile_scale: float`, `projectile_speed: float`, `range_value: float`
   - `cooldown: float`, `angle: float`, `mount_offsets: Array[Vector2]`
   - Methods: `apply_count_upgrade()`, `apply_damage_upgrade()`, `apply_fire_rate_upgrade()`

2. **Create `scripts/camel_entity.gd`** — a `Node2D` class:
   - `camel_position: Vector2`, `velocity: Vector2`, `wobble: float`, `scale_factor: float`, `alive: bool`
   - Move `_update_camels()` and `_draw_camels()` logic into this entity

3. **Create `scripts/wave_data.gd`** — a `RefCounted` class:
   - `count: int`, `level: int`, `wave: int`, `spawn_interval: float`
   - `elapsed: float`, `next_spawn_at: float`, `completed: bool`, `spawned_count: int`
   - `roster_spawned: Dictionary`, `threat: String`

4. **Refactor `enemy.gd`**: `build_enemy()` should return an `EnemyEntity` directly (or accept an existing one and call setup internally with typed args, not a dict).

5. **Update `main.gd`**: replace all `arsenals[id]["field"]` patterns with `arsenals[id].field` typed access.

### Constraints

- Do NOT change game behavior or balance values
- Do NOT rename files that already exist — create new ones alongside
- Keep `class_name` declarations for all new classes
- Preserve the existing scene tree — new classes should not require `.tscn` changes unless they are `Node2D` entities added via code

### Done When

- Zero `Dictionary` usage for arsenals, camels, or wave data in `main.gd`
- `enemy.gd` no longer returns raw dictionaries
- All new classes have typed properties (no `var x` without type hints)
- Game runs identically via `--headless --quit` without errors

---

## Priority 2 — Use Enums Instead of String Constants [DONE]

### Goal

Replace string-based state machine and entity type identifiers with GDScript enums for compile-time safety.

### Context

- `main.gd` lines 15-19: `STATE_IDLE`, `STATE_FIGHTING`, etc. are `const String`
- Enemy types: `"saucer"`, `"cruiser"`, `"flagship"`, `"boss"` are strings everywhere
- Arsenal IDs: `"machine_gun"`, `"missiles"`, `"emp"` are strings everywhere
- Upgrade kinds: `"count"`, `"damage"`, `"fire_rate"` are strings

### Tasks

1. Create `scripts/enums.gd` (or a `const` file) with:
   ```gdscript
   class_name GameEnums

   enum GameState { IDLE, FIGHTING, UPGRADE, GAME_OVER, VICTORY }
   enum EnemyType { SAUCER, CRUISER, FLAGSHIP, BOSS }
   enum ArsenalId { MACHINE_GUN, MISSILES, EMP }
   enum UpgradeKind { COUNT, DAMAGE, FIRE_RATE }
   enum ProjectileKind { LASER, RAM, RAY, TENTACLE }
   ```

2. Replace all string comparisons (`match type_name: "saucer":`) with enum matches.
3. Update `enemy.gd`, `wave_manager.gd`, `enemy_entity.gd`, `projectile_entity.gd` to use enums.
4. Update `main.gd` state machine to use `GameEnums.GameState`.

### Constraints

- Migrate incrementally: one enum at a time if needed
- Keep backward-compatible `_to_string()` helpers for UI display text (French labels)

### Done When

- No string literals used for state, enemy types, arsenal IDs, or upgrade kinds in game logic
- All `match` statements use enum values
- Game runs identically

---

## Priority 3 — Eliminate Code Duplication [DONE]

### Goal

Remove duplicated rendering logic that exists in multiple files.

### Context

- `_draw_saucer_beam()` is implemented in BOTH `main.gd` (line 390) AND `projectile_entity.gd` (line 105). They are identical.
- `_draw_enemies()` in `main.gd` (line 361) is a `pass` — the actual drawing is done by `EnemyEntity._draw()`. The empty function is dead code.
- `_draw_projectiles()` in `main.gd` (line 382) is a `pass` — same situation.
- `_draw_explosions()` in `main.gd` (line 386) is a `pass` — same situation.
- `update_spawn_intro()` exists in BOTH `enemy.gd` (static, dict-based) AND `enemy_entity.gd` (instance method). Only the entity version is used.

### Tasks

1. Delete `_draw_saucer_beam()` from `main.gd` — it is only used via `ProjectileEntity._draw()`.
2. Delete `_draw_enemies()`, `_draw_projectiles()`, `_draw_explosions()` from `main.gd` — they are empty `pass` stubs.
3. Delete `update_spawn_intro()` from `enemy.gd` — the `EnemyEntity` version is what gets called.
4. Verify no callers reference the deleted methods.

### Constraints

- Only delete confirmed dead code
- Run `--headless --quit` after each deletion to verify no errors

### Done When

- No duplicate method implementations across files
- No empty `pass` methods remain
- Game runs without errors

---

## Priority 4 — Extract Magic Numbers into Named Constants [DONE]

### Goal

Replace hardcoded numeric values with named constants, grouped logically.

### Context

Key magic numbers scattered in `main.gd`:
- `1320`, `760` — screen bounds (lines 636, 652)
- `66` — dome visual radius (line 322)
- `18.0` — collision distance (line 628)
- `0.22` — dome flash duration (line 717)
- `0.16` — house FX cooldown (line 721)
- `2.8`, `1.9` — rotation speeds (lines 876-878)
- `0.12` — level rotation scale (line 873)
- `0.18` — angle tolerance for firing (line 603)
- `230.0`, `190.0` — enemy projectile speeds (lines 738-740)
- `34.0`, `26.0` — camel absorb range (line 810)
- `28.0` — mount overlap distance (line 864)

### Tasks

1. Group constants at the top of `main.gd` (or in a dedicated `scripts/game_config.gd` if the list exceeds 30 entries):
   ```gdscript
   const SCREEN_WIDTH := 1280
   const SCREEN_HEIGHT := 720
   const SCREEN_MARGIN := 40
   const DOME_VISUAL_RADIUS := 66.0
   const COLLISION_DISTANCE := 18.0
   const DOME_FLASH_DURATION := 0.22
   const HOUSE_FX_COOLDOWN := 0.16
   # ... etc
   ```
2. Replace each magic number with its constant name.
3. Do NOT change any numeric value — only extract and name.

### Constraints

- Do not move values that are already named constants
- Keep constants close to where they are used if they are truly local (e.g., a loop limit)
- Prefer a single `game_config.gd` file if more than 20 constants

### Done When

- No unexplained numeric literal in game logic (rendering pixel positions are acceptable)
- All gameplay-relevant numbers have a named constant
- Game behavior unchanged

---

## Priority 5 — Split main.gd Into Focused Controllers [DONE]

### Goal

Break `main.gd` (1541 lines) into smaller, focused scripts. This is the highest-impact refactor but depends on Priorities 1-2 being done first.

### Context

Current `main.gd` responsibilities:
- Game state machine (~50 lines)
- Wave spawning coordination (~60 lines)
- Enemy update loop (~55 lines)
- Arsenal firing logic (~80 lines)
- Projectile update and collision (~40 lines)
- Base damage and health (~30 lines)
- UI/HUD management (~120 lines)
- Audio management (~50 lines)
- Camel logic (~40 lines)
- Upgrade system (~100 lines)
- Screenshot feature (~50 lines)
- Leaderboard integration (~20 lines)
- Drawing/rendering (~150 lines)
- Pause/menu logic (~50 lines)
- Utility functions (~30 lines)

### Tasks

1. **`scripts/audio_manager.gd`** — Autoload singleton:
   - Move all `AudioStreamPlayer` creation, `_play_weapon_sound()`, `_apply_audio_settings()`, `_set_player_volume()`, `_on_music_finished()`
   - Expose: `play_weapon(arsenal_id)`, `play_explosion()`, `play_camel_absorb()`, `set_sound_volume(v)`, `set_music_volume(v)`

2. **`scripts/combat_controller.gd`** — Node attached under `World`:
   - Move: `_update_enemies()`, `_update_base_fire()`, `_update_projectiles()`, `_apply_damage_to_base()`, `_spawn_explosion()`, `_spawn_enemy_projectile()`, `_spawn_enemy_beam()`, `_spawn_enemy_tentacle_fx()`, `_try_absorb_camel()`
   - Move targeting: `_find_targets_in_range()`, `_find_primary_target_in_range()`, `_find_front_enemy_index()`

3. **`scripts/upgrade_controller.gd`** — Node or RefCounted:
   - Move: `_build_upgrade_options()`, `_build_upgrade_option()`, `_apply_upgrade()`, `_rebuild_upgrade_buttons()`, `_upgrade_icon()`, `_update_upgrade_buttons()`

4. **`scripts/hud_controller.gd`** — Script on the HUD CanvasLayer:
   - Move: `_update_ui()`, all label updates, `_state_label()`, `_roster_text()`, `_arsenal_summary_text()`, `_format_time()`, `_format_number()`

5. **`scripts/screenshot_manager.gd`** — Small utility:
   - Move: `_save_screenshot()`, `_preferred_screenshot_directory()`, `_screenshot_timestamp()`, `_show_screenshot_notice()`

6. **Keep in `main.gd`** (~200-300 lines):
   - State machine: `_process()`, `_unhandled_input()`, state transitions
   - Lifecycle: `_ready()`, `_start_new_run()`, `_start_wave()`, `_on_wave_cleared()`, `_on_game_over()`, `_on_victory()`
   - Drawing: `_draw()`, `_draw_background()`, `_draw_base()`, `_draw_arsenal_mount()`
   - Coordination between controllers

### Constraints

- Introduce one controller at a time, test after each
- Use signals for loose coupling between controllers
- Do NOT change the scene tree structure in `.tscn` unless adding new nodes for controllers
- New scripts must be attached via `_ready()` or added as child nodes — do not require manual `.tscn` edits
- `main.gd` stays as the root script on the Main node

### Done When

- `main.gd` is under 400 lines
- Each new controller is under 250 lines
- No circular dependencies between controllers
- Game runs identically
- `--headless --quit` passes without errors

---

## Priority 6 — Signals for Inter-Component Communication [DONE]

### Goal

Replace direct method calls between future controllers with Godot signals.

### Context

Currently `main.gd` calls everything directly. After the split (Priority 5), controllers will need to communicate. Use signals to avoid tight coupling.

### Tasks

1. Define signals on relevant controllers:
   - `CombatController`: `signal enemy_destroyed(enemy: EnemyEntity)`, `signal base_damaged(amount: float)`, `signal camel_absorbed()`
   - `Main`: `signal wave_started(level: int, wave: int)`, `signal wave_cleared()`, `signal game_over()`, `signal victory()`
2. Connect signals in `_ready()` instead of direct calls.
3. Replace `combat_score += 1` scattered calls with signal-driven score updates.

### Constraints

- Only introduce signals where two separate scripts need to communicate
- Do not over-engineer: if a method is only called from its own script, no signal needed

### Done When

- No controller directly calls methods on another controller
- All inter-controller communication uses signals
- Game behavior unchanged

---

## Priority 7 — Minor Code Quality Fixes [DONE]

### Goal

Fix small but important quality issues.

### Tasks

1. **Projectile bounds**: Replace hardcoded `1320`/`760` screen bounds with constants or `get_viewport_rect().size`.

2. **Mount placement fallback**: The `_random_arsenal_mount_offset()` fallback after 32 attempts (line 869) can still overlap. Add a minimum-distance guarantee or increase attempts.

3. **Audio bus safety**: `player.bus = "Master"` assumes the bus exists. Add a check:
   ```gdscript
   if AudioServer.get_bus_index("Master") == -1:
       push_warning("Master audio bus not found")
   ```

4. **Settings persistence**: Save `sounds_volume` and `music_volume` to `user://settings.json` so they persist across sessions.

5. **Leaderboard robustness**: Add schema validation when loading `leaderboard.json` — reject entries missing `name`, `time`, or `timestamp` keys.

6. **Pause during upgrade**: Allow pausing during `STATE_UPGRADE` (currently `_toggle_pause()` only works in `STATE_FIGHTING`).

### Constraints

- Each fix is independent — can be done in any order
- No gameplay balance changes

### Done When

- Each fix is applied and verified
- No new bugs introduced

---

## Execution Order

Codex should execute these priorities in order because each builds on the previous:

1. **P3 first** (dead code cleanup) — quick win, reduces noise
2. **P4** (magic numbers) — makes subsequent refactors clearer
3. **P2** (enums) — establishes type vocabulary
4. **P1** (typed classes) — replaces dictionaries with proper types
5. **P5** (split main.gd) — major architectural improvement
6. **P6** (signals) — loose coupling for the split
7. **P7** (quality fixes) — polish

Each priority is a standalone commit. Test after each with `--headless --quit`.
