class_name CombatSupport
extends RefCounted

const Arsenal = preload("res://scripts/arsenal.gd")
const EnemyEntity = preload("res://scripts/enemy_entity.gd")
const GameConfig = preload("res://scripts/game_config.gd")
const GameEnums = preload("res://scripts/enums.gd")


static func arsenal_mount_positions(arsenal: Arsenal, base_world_pos: Vector2) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for offset in arsenal.mount_offsets:
		positions.append(base_world_pos + offset)
	return positions


static func arsenal_rotation_speed(arsenal_id: int, current_level: int) -> float:
	var level_scale: float = 1.0 + float(current_level - 1) * GameConfig.ROTATION_LEVEL_SCALE
	if arsenal_id == GameEnums.ArsenalId.MACHINE_GUN:
		return GameConfig.MACHINE_GUN_ROTATION_SPEED * level_scale
	if arsenal_id == GameEnums.ArsenalId.MISSILES:
		return GameConfig.MISSILE_ROTATION_SPEED * level_scale
	return 0.0


static func move_angle_toward(current: float, target: float, max_delta: float) -> float:
	var delta: float = angle_distance(current, target)
	return target if abs(delta) <= max_delta else current + sign(delta) * max_delta


static func angle_distance(from_angle: float, to_angle: float) -> float:
	return wrapf(to_angle - from_angle, -PI, PI)


static func find_targets_in_range(alive_enemies: Array[EnemyEntity], max_targets: int, range_value: float, origin: Vector2) -> Array[EnemyEntity]:
	var ordered: Array[Dictionary] = []
	for enemy in alive_enemies:
		var distance: float = enemy.global_position.distance_to(origin)
		if distance <= range_value:
			ordered.append({"distance": distance, "enemy": enemy})
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["distance"]) < float(b["distance"]))
	var results: Array[EnemyEntity] = []
	for index in range(min(max_targets, ordered.size())):
		results.append(ordered[index]["enemy"])
	return results


static func find_primary_target_in_range(alive_enemies: Array[EnemyEntity], range_value: float, origin: Vector2) -> EnemyEntity:
	var targets: Array[EnemyEntity] = find_targets_in_range(alive_enemies, 1, range_value, origin)
	return null if targets.is_empty() else targets[0]


static func is_on_screen(position: Vector2, viewport_size: Vector2) -> bool:
	return position.x > -GameConfig.SCREEN_MARGIN and position.y > -GameConfig.SCREEN_MARGIN and position.x < viewport_size.x + GameConfig.SCREEN_MARGIN and position.y < viewport_size.y + GameConfig.SCREEN_MARGIN


static func free_nodes(nodes: Array) -> void:
	for node in nodes:
		if is_instance_valid(node):
			node.queue_free()
