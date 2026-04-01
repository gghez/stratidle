extends RefCounted

const WaveData = preload("res://scripts/wave_data.gd")
const GameEnums = preload("res://scripts/enums.gd")


static func build_wave_data(level_number: int, wave_number: int, waves_per_level: int, wave_duration: float) -> WaveData:
	var progress := float(wave_number - 1) / float(waves_per_level - 1)
	var spawn_interval: float = lerp(1.0, 0.2, progress)
	var count: int = int(ceil(wave_duration / spawn_interval))
	return WaveData.new().setup(
		count,
		level_number,
		wave_number,
		spawn_interval,
		wave_threat_label(level_number, wave_number)
	)


static func spawn_position_for_index(spawn_index: int, enemy_id: int) -> Vector2:
	var lane_count: int = 9
	var lane_index: int = randi_range(0, lane_count - 1)
	var lane_x: float = lerp(110.0, 1170.0, float(lane_index) / float(lane_count - 1))
	var start_x: float = clamp(lane_x + randf_range(-56.0, 56.0), 72.0, 1208.0)
	var start_y: float = randf_range(-200.0, -88.0) - float(spawn_index % 4) * randf_range(10.0, 24.0) - float(enemy_id % 3) * 8.0
	return Vector2(start_x, start_y)


static func select_enemy_type(level_number: int, wave_number: int, spawn_index: int) -> int:
	var roll := int((spawn_index * 17 + wave_number * 9 + level_number * 13) % 100)
	if wave_number == 10 and spawn_index > 0 and spawn_index % max(14 - level_number, 6) == 0:
		return GameEnums.EnemyType.BOSS
	if wave_number >= 8 and roll < min(8 + level_number, 22):
		return GameEnums.EnemyType.FLAGSHIP
	if wave_number >= 7 and roll > 84:
		return GameEnums.EnemyType.FLAGSHIP
	if wave_number >= 4 and roll > 58:
		return GameEnums.EnemyType.CRUISER
	return GameEnums.EnemyType.SAUCER


static func wave_threat_label(level_number: int, wave_number: int) -> String:
	if wave_number == 10 or level_number >= 9:
		return "Boss"
	if wave_number >= 7:
		return "Majeure"
	if wave_number >= 4:
		return "Soutenue"
	return "Faible"
