extends RefCounted

const EnemyEntity = preload("res://scripts/enemy_entity.gd")
const GameEnums = preload("res://scripts/enums.gd")

static func enemy_explosion_size(enemy_type: int) -> float:
	match enemy_type:
		GameEnums.EnemyType.SAUCER:
			return 42.0
		GameEnums.EnemyType.CRUISER:
			return 54.0
		GameEnums.EnemyType.FLAGSHIP:
			return 68.0
		GameEnums.EnemyType.BOSS:
			return 96.0
		_:
			return 48.0


static func build_enemy(enemy_type: int, level_number: int, wave_number: int, enemy_id: int, start_position: Vector2) -> EnemyEntity:
	var stats: Dictionary = enemy_template(enemy_type)
	var scale: float = 1.0 + (level_number - 1) * 0.22
	var distant_spawn_chance: float = clamp(0.18 + float(wave_number - 1) * 0.018 + float(level_number - 1) * 0.01, 0.18, 0.42)
	var use_distant_intro: bool = randf() < distant_spawn_chance
	var intro_origin: Vector2 = Vector2(
		clamp(start_position.x + randf_range(-220.0, 220.0), 48.0, 1232.0),
		randf_range(-430.0, -300.0)
	)
	var intro_duration: float = randf_range(0.85, 1.65)
	var initial_position: Vector2 = intro_origin if use_distant_intro else start_position
	var initial_scale: float = 0.0 if use_distant_intro else 1.0
	var enemy := EnemyEntity.new()
	enemy.setup(
		enemy_id,
		enemy_type,
		GameEnums.enemy_name(enemy_type),
		int(stats["rank"]),
		float(stats["hp"]) * scale,
		float(stats["hp"]) * scale,
		float(stats["armor"]) + (level_number - 1) * float(stats["armor_gain"]),
		float(stats["speed"]) + (level_number - 1) * float(stats["speed_gain"]),
		float(stats["fire_rate"]) + (level_number - 1) * float(stats["fire_gain"]),
		float(stats["shot_power"]) * (1.0 + (level_number - 1) * 0.18),
		initial_position,
		randf_range(0.0, 1.2),
		randf_range(0.0, PI * 2.0),
		initial_scale,
		1.0,
		use_distant_intro,
		0.0,
		intro_duration,
		intro_origin,
		start_position
	)
	return enemy


static func enemy_template(enemy_type: int) -> Dictionary:
	match enemy_type:
		GameEnums.EnemyType.SAUCER:
			return {
				"rank": 1,
				"hp": 18.0,
				"armor": 0.5,
				"speed": 42.0,
				"fire_rate": 1.0,
				"shot_power": 1.0,
				"armor_gain": 0.08,
				"speed_gain": 0.8,
				"fire_gain": 0.02
			}
		GameEnums.EnemyType.CRUISER:
			return {
				"rank": 2,
				"hp": 56.0,
				"armor": 2.0,
				"speed": 30.0,
				"fire_rate": 0.55,
				"shot_power": 3.0,
				"armor_gain": 0.18,
				"speed_gain": 0.5,
				"fire_gain": 0.016
			}
		GameEnums.EnemyType.FLAGSHIP:
			return {
				"rank": 3,
				"hp": 140.0,
				"armor": 5.0,
				"speed": 20.0,
				"fire_rate": 0.2,
				"shot_power": 10.0,
				"armor_gain": 0.35,
				"speed_gain": 0.25,
				"fire_gain": 0.012
			}
		GameEnums.EnemyType.BOSS:
			return {
				"rank": 5,
				"hp": 520.0,
				"armor": 9.0,
				"speed": 14.0,
				"fire_rate": 1.0,
				"shot_power": 10.0,
				"armor_gain": 0.5,
				"speed_gain": 0.15,
				"fire_gain": 0.02
			}
		_:
			return {}
