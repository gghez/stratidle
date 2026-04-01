class_name ArsenalLayout
extends RefCounted

const Arsenal = preload("res://scripts/arsenal.gd")
const GameConfig = preload("res://scripts/game_config.gd")
const GameEnums = preload("res://scripts/enums.gd")


static func mount_position(arsenal_id: int) -> Vector2:
	if arsenal_id == GameEnums.ArsenalId.MACHINE_GUN:
		return GameConfig.BASE_WORLD_POS + Vector2(-22, 18)
	if arsenal_id == GameEnums.ArsenalId.MISSILES:
		return GameConfig.BASE_WORLD_POS + Vector2(24, 20)
	return GameConfig.BASE_WORLD_POS + Vector2(0, -40)


static func mount_positions(arsenal: Arsenal) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for offset in arsenal.mount_offsets:
		positions.append(GameConfig.BASE_WORLD_POS + offset)
	return positions


static func sync_mounts(arsenal: Arsenal) -> void:
	if arsenal.count <= 0:
		arsenal.mount_offsets.clear()
		return
	if arsenal.mount_offsets.is_empty():
		arsenal.mount_offsets.append(mount_position(arsenal.id) - GameConfig.BASE_WORLD_POS)
	while arsenal.mount_offsets.size() < arsenal.count:
		arsenal.mount_offsets.append(_random_mount_offset(arsenal.mount_offsets))
	while arsenal.mount_offsets.size() > arsenal.count:
		arsenal.mount_offsets.resize(arsenal.count)


static func total_damage(arsenals: Array[Arsenal]) -> float:
	var total: float = 0.0
	for arsenal in arsenals:
		total += arsenal.damage * arsenal.count
	return total


static func total_fire_rate(arsenals: Array[Arsenal]) -> float:
	var total: float = 0.0
	for arsenal in arsenals:
		total += arsenal.fire_rate * arsenal.count
	return total


static func _random_mount_offset(existing_offsets: Array[Vector2]) -> Vector2:
	for _attempt in range(GameConfig.MOUNT_PLACEMENT_ATTEMPTS):
		var angle: float = randf_range(0.15, PI - 0.15)
		var candidate: Vector2 = Vector2(cos(angle), sin(angle)) * randf_range(54.0, 118.0) + Vector2(0, 22)
		if _mount_offset_is_valid(candidate, existing_offsets):
			return candidate
	for radius in [124.0, 132.0, 140.0, 148.0]:
		for step in range(24):
			var fallback: Vector2 = Vector2(cos(float(step) / 24.0 * PI), sin(float(step) / 24.0 * PI)) * radius + Vector2(0, 22)
			if _mount_offset_is_valid(fallback, existing_offsets):
				return fallback
	return Vector2(0, 22)


static func _mount_offset_is_valid(candidate: Vector2, existing_offsets: Array[Vector2]) -> bool:
	for offset in existing_offsets:
		if candidate.distance_to(offset) < GameConfig.MOUNT_MIN_DISTANCE:
			return false
	return true
