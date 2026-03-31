extends Node2D

const TOTAL_LEVELS := 11
const WAVES_PER_LEVEL := 10
const MAX_LEADERBOARD_ENTRIES := 10
const LEADERBOARD_PATH := "user://leaderboard.json"

const STATE_IDLE := "idle"
const STATE_FIGHTING := "fighting"
const STATE_UPGRADE := "upgrade"
const STATE_GAME_OVER := "game_over"
const STATE_VICTORY := "victory"

const BASE_WORLD_POS := Vector2(640.0, 620.0)
const BASE_RADIUS := 95.0
const BASE_FIRE_RANGE_DEFAULT := 720.0
const WAVE_DURATION := 30.0

var camel_texture: Texture2D = preload("res://assets/sprites/camel.svg")
var house_texture: Texture2D = preload("res://assets/sprites/base_house.svg")
var machine_gun_texture: Texture2D = preload("res://assets/sprites/machine_gun.svg")
var missile_launcher_texture: Texture2D = preload("res://assets/sprites/missile_launcher.svg")
var emp_texture: Texture2D = preload("res://assets/sprites/emp.svg")
var enemy_textures := {
	"saucer": preload("res://assets/sprites/saucer.svg"),
	"cruiser": preload("res://assets/sprites/cruiser.svg"),
	"flagship": preload("res://assets/sprites/flagship.svg"),
	"boss": preload("res://assets/sprites/boss.svg")
}
var explosion_frames: Array[Texture2D] = []
var explosion_sound: AudioStream
var machine_gun_sound: AudioStream
var missile_launch_sound: AudioStream
var emp_sound: AudioStream

@onready var run_state_label: Label = $HUD/HudRoot/Margin/RootRow/LeftColumn/StatusPanel/StatusMargin/StatusVBox/RunStateLabel
@onready var timer_label: Label = $HUD/HudRoot/Margin/RootRow/LeftColumn/StatusPanel/StatusMargin/StatusVBox/TimerLabel
@onready var level_label: Label = $HUD/HudRoot/Margin/RootRow/LeftColumn/StatusPanel/StatusMargin/StatusVBox/LevelLabel
@onready var wave_label: Label = $HUD/HudRoot/Margin/RootRow/LeftColumn/StatusPanel/StatusMargin/StatusVBox/WaveLabel
@onready var base_label: Label = $HUD/HudRoot/Margin/RootRow/LeftColumn/StatusPanel/StatusMargin/StatusVBox/BaseLabel
@onready var wave_stats_label: Label = $HUD/HudRoot/Margin/RootRow/LeftColumn/StatusPanel/StatusMargin/StatusVBox/WaveStatsLabel
@onready var score_label: Label = $HUD/HudRoot/Margin/RootRow/LeftColumn/StatusPanel/StatusMargin/StatusVBox/ScoreLabel
@onready var arsenal_label: Label = $HUD/HudRoot/Margin/RootRow/LeftColumn/StatusPanel/StatusMargin/StatusVBox/ArsenalLabel
@onready var roster_label: Label = $HUD/HudRoot/Margin/RootRow/LeftColumn/StatusPanel/StatusMargin/StatusVBox/RosterLabel
@onready var message_label: Label = $HUD/HudRoot/Margin/RootRow/LeftColumn/MessagePanel/MessageMargin/MessageVBox/MessageLabel
@onready var upgrade_panel: PanelContainer = $HUD/HudRoot/Margin/RootRow/LeftColumn/UpgradePanel
@onready var upgrade_subtitle: Label = $HUD/HudRoot/Margin/RootRow/LeftColumn/UpgradePanel/UpgradeMargin/UpgradeVBox/UpgradeSubtitle
@onready var upgrade_options_grid: GridContainer = $HUD/HudRoot/Margin/RootRow/LeftColumn/UpgradePanel/UpgradeMargin/UpgradeVBox/UpgradeScroll/UpgradeOptionsGrid
@onready var start_button: Button = $HUD/HudRoot/Margin/RootRow/LeftColumn/ControlPanel/ControlMargin/ControlVBox/ButtonRow/StartButton
@onready var restart_button: Button = $HUD/HudRoot/Margin/RootRow/LeftColumn/ControlPanel/ControlMargin/ControlVBox/ButtonRow/RestartButton
@onready var name_edit: LineEdit = $HUD/HudRoot/Margin/RootRow/LeftColumn/ControlPanel/ControlMargin/ControlVBox/ScoreRow/NameEdit
@onready var submit_score_button: Button = $HUD/HudRoot/Margin/RootRow/LeftColumn/ControlPanel/ControlMargin/ControlVBox/ScoreRow/SubmitScoreButton
@onready var leaderboard_text: RichTextLabel = $HUD/HudRoot/Margin/RootRow/RightColumn/LeaderboardPanel/LeaderboardMargin/LeaderboardVBox/LeaderboardText
@onready var left_column: VBoxContainer = $HUD/HudRoot/Margin/RootRow/LeftColumn
@onready var right_column: VBoxContainer = $HUD/HudRoot/Margin/RootRow/RightColumn
@onready var status_panel: PanelContainer = $HUD/HudRoot/Margin/RootRow/LeftColumn/StatusPanel
@onready var message_panel: PanelContainer = $HUD/HudRoot/Margin/RootRow/LeftColumn/MessagePanel
@onready var control_panel: PanelContainer = $HUD/HudRoot/Margin/RootRow/LeftColumn/ControlPanel
@onready var leaderboard_panel: PanelContainer = $HUD/HudRoot/Margin/RootRow/RightColumn/LeaderboardPanel
@onready var shortcut_hint: Label = $HUD/HudRoot/ShortcutHint

var upgrade_buttons: Array[Button] = []
var pending_upgrade_options: Array[Dictionary] = []
var leaderboard: Array[Dictionary] = []

var state := STATE_IDLE
var run_time := 0.0
var score_saved := false
var combat_score := 0
var current_message := "Lancez une run pour voir arriver les envahisseurs."

var current_level := 1
var current_wave := 1
var current_wave_data: Dictionary = {}
var alive_enemies: Array[Dictionary] = []
var camels: Array[Dictionary] = []
var player_projectiles: Array[Dictionary] = []
var enemy_projectiles: Array[Dictionary] = []

var dome_max_hp := 0.0
var dome_hp := 0.0
var house_max_hp := 0.0
var house_hp := 0.0
var arsenals := {}
var explosion_player: AudioStreamPlayer
var weapon_players := {}
var explosions: Array[Dictionary] = []
var dome_flash_timer := 0.0
var house_fx_cooldown := 0.0
var show_combat_stats := true
var show_leaderboard := true
var next_enemy_id := 0


func _ready() -> void:
	_load_runtime_assets()

	explosion_player = AudioStreamPlayer.new()
	explosion_player.stream = explosion_sound
	explosion_player.bus = "Master"
	explosion_player.max_polyphony = 6
	add_child(explosion_player)
	_setup_weapon_audio_players()

	start_button.pressed.connect(_on_start_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	submit_score_button.pressed.connect(_on_submit_score_pressed)

	_load_leaderboard()
	_setup_camels()
	_reset_to_idle()
	_refresh_leaderboard_text()
	_update_ui()
	queue_redraw()


func _load_runtime_assets() -> void:
	explosion_frames = []
	for frame_path in [
		"res://assets/effects/explosion-01.png",
		"res://assets/effects/explosion-02.png",
		"res://assets/effects/explosion-03.png",
		"res://assets/effects/explosion-04.png",
		"res://assets/effects/explosion-05.png"
	]:
		var frame_texture := _load_texture_from_image_file(frame_path)
		if frame_texture != null:
			explosion_frames.append(frame_texture)

	machine_gun_sound = _load_wav_stream("res://assets/audio/machine_gun.wav")
	missile_launch_sound = _load_wav_stream("res://assets/audio/missile_launch.wav")
	emp_sound = _load_wav_stream("res://assets/audio/emp.wav")
	explosion_sound = _load_wav_stream("res://assets/audio/explosion.wav")


func _load_texture_from_image_file(path: String) -> Texture2D:
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		return null
	return ImageTexture.create_from_image(image)


func _load_wav_stream(path: String) -> AudioStreamWAV:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var bytes := file.get_buffer(file.get_length())
	if bytes.size() < 44:
		return null
	if _read_ascii(bytes, 0, 4) != "RIFF" or _read_ascii(bytes, 8, 4) != "WAVE":
		return null

	var offset := 12
	var channel_count := 1
	var sample_rate := 44100
	var bits_per_sample := 16
	var pcm_data := PackedByteArray()

	while offset + 8 <= bytes.size():
		var chunk_id := _read_ascii(bytes, offset, 4)
		var chunk_size := _read_u32_le(bytes, offset + 4)
		offset += 8
		if chunk_id == "fmt ":
			if chunk_size >= 16 and offset + chunk_size <= bytes.size():
				var format_code := _read_u16_le(bytes, offset)
				if format_code != 1:
					return null
				channel_count = _read_u16_le(bytes, offset + 2)
				sample_rate = _read_u32_le(bytes, offset + 4)
				bits_per_sample = _read_u16_le(bytes, offset + 14)
		elif chunk_id == "data":
			if offset + chunk_size <= bytes.size():
				pcm_data = bytes.slice(offset, offset + chunk_size)
				break
		offset += chunk_size
		if offset % 2 == 1:
			offset += 1

	if pcm_data.is_empty():
		return null

	var stream := AudioStreamWAV.new()
	stream.data = pcm_data
	stream.mix_rate = sample_rate
	stream.stereo = channel_count == 2
	match bits_per_sample:
		8:
			stream.format = AudioStreamWAV.FORMAT_8_BITS
		16:
			stream.format = AudioStreamWAV.FORMAT_16_BITS
		_:
			return null
	return stream


func _read_ascii(bytes: PackedByteArray, offset: int, length: int) -> String:
	var chars := ""
	for index in range(length):
		chars += char(bytes[offset + index])
	return chars


func _read_u16_le(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)


func _read_u32_le(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8) | (int(bytes[offset + 2]) << 16) | (int(bytes[offset + 3]) << 24)


func _process(delta: float) -> void:
	_update_camels(delta)
	_update_explosions(delta)
	dome_flash_timer = max(dome_flash_timer - delta, 0.0)
	house_fx_cooldown = max(house_fx_cooldown - delta, 0.0)

	if state == STATE_FIGHTING:
		run_time += delta
		_update_wave_spawning(delta)
		_update_enemies(delta)
		_update_arsenal_orientation(delta)
		_update_base_fire(delta)
		_update_projectiles(delta)
		_resolve_wave_state()

	queue_redraw()
	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	if not event.is_pressed() or event.is_echo():
		return
	if not _overlay_allowed():
		return

	if event.keycode == KEY_S:
		show_combat_stats = not show_combat_stats
		_update_ui()
	elif event.keycode == KEY_L:
		show_leaderboard = not show_leaderboard
		_update_ui()


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	_draw_background(viewport_size)
	_draw_camels()
	_draw_base()
	_draw_enemies()
	_draw_projectiles()
	_draw_explosions()


func _draw_background(viewport_size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.92, 0.74, 0.44, 1.0), true)
	draw_rect(Rect2(0, 0, viewport_size.x, viewport_size.y * 0.56), Color(0.76, 0.88, 0.98, 1.0), true)

	var horizon_points := PackedVector2Array([
		Vector2(0, 420),
		Vector2(140, 392),
		Vector2(300, 408),
		Vector2(460, 372),
		Vector2(660, 402),
		Vector2(840, 380),
		Vector2(1040, 414),
		Vector2(1280, 396),
		Vector2(1280, 720),
		Vector2(0, 720)
	])
	draw_colored_polygon(horizon_points, Color(0.84, 0.63, 0.33, 1.0))

	var dune_front := PackedVector2Array([
		Vector2(0, 520),
		Vector2(180, 500),
		Vector2(360, 542),
		Vector2(620, 512),
		Vector2(880, 548),
		Vector2(1160, 524),
		Vector2(1280, 550),
		Vector2(1280, 720),
		Vector2(0, 720)
	])
	draw_colored_polygon(dune_front, Color(0.91, 0.71, 0.38, 1.0))


func _draw_camels() -> void:
	for camel in camels:
		if not bool(camel.get("alive", true)):
			continue
		var pos: Vector2 = camel["position"]
		var scale: float = camel["scale"]
		var color := Color(1.0, 1.0, 1.0, 0.28 + scale * 0.24)
		_draw_sprite_centered(camel_texture, pos + Vector2(0, -6 * scale), Vector2(64, 48) * scale, color)


func _draw_base() -> void:
	var ground_color := Color(0.55, 0.36, 0.19, 1.0)
	draw_circle(BASE_WORLD_POS + Vector2(0, 56), BASE_RADIUS + 26, Color(0.72, 0.57, 0.29, 1.0))
	draw_rect(Rect2(BASE_WORLD_POS + Vector2(-56, 44), Vector2(112, 12)), Color(0.32, 0.23, 0.17, 1.0), true)
	draw_rect(Rect2(BASE_WORLD_POS + Vector2(-44, -8), Vector2(88, 72)), ground_color, true)
	_draw_sprite_centered(house_texture, BASE_WORLD_POS + Vector2(0, 24), Vector2(120, 120))
	if dome_hp > 0.0:
		draw_circle(BASE_WORLD_POS + Vector2(0, -4), 66, Color(0.53, 0.78, 0.95, 0.22), true)
		draw_arc(BASE_WORLD_POS + Vector2(0, -4), 66, PI, TAU, 48, Color(0.7, 0.93, 1.0, 0.75), 3.0)
		if dome_flash_timer > 0.0:
			var flash_alpha: float = min(0.45, dome_flash_timer * 2.4)
			draw_circle(BASE_WORLD_POS + Vector2(0, -4), 66, Color(1.0, 0.18, 0.12, flash_alpha), true)
			draw_arc(BASE_WORLD_POS + Vector2(0, -4), 66, PI, TAU, 48, Color(1.0, 0.4, 0.32, min(0.95, flash_alpha + 0.2)), 4.0)

	var dome_ratio := 0.0
	if dome_max_hp > 0.0:
		dome_ratio = clamp(dome_hp / dome_max_hp, 0.0, 1.0)
	var house_ratio := 0.0
	if house_max_hp > 0.0:
		house_ratio = clamp(house_hp / house_max_hp, 0.0, 1.0)
	draw_rect(Rect2(BASE_WORLD_POS + Vector2(-80, -108), Vector2(160, 10)), Color(0.18, 0.12, 0.08, 0.8), true)
	draw_rect(Rect2(BASE_WORLD_POS + Vector2(-78, -106), Vector2(156 * dome_ratio, 6)), Color(0.36, 0.84, 1.0, 1.0), true)
	draw_rect(Rect2(BASE_WORLD_POS + Vector2(-80, -94), Vector2(160, 10)), Color(0.18, 0.12, 0.08, 0.8), true)
	draw_rect(Rect2(BASE_WORLD_POS + Vector2(-78, -92), Vector2(156 * house_ratio, 6)), Color(0.98, 0.76, 0.36, 1.0), true)

	_draw_arsenal_mount("machine_gun")
	_draw_arsenal_mount("missiles")


func _draw_arsenal_mount(arsenal_id: String) -> void:
	var arsenal: Dictionary = arsenals.get(arsenal_id, {})
	if int(arsenal.get("count", 0)) <= 0:
		return

	var mount := _arsenal_mount_position(arsenal_id)
	var angle: float = float(arsenal.get("angle", -PI / 2.0))
	if arsenal_id == "machine_gun":
		_draw_rotated_sprite(machine_gun_texture, mount, Vector2(44, 44), angle + PI / 2.0)
	else:
		_draw_rotated_sprite(missile_launcher_texture, mount, Vector2(52, 52), angle + PI / 2.0)


func _draw_enemies() -> void:
	for enemy in alive_enemies:
		var pos: Vector2 = enemy["position"]
		var hp_ratio := 0.0
		if enemy["max_hp"] > 0.0:
			hp_ratio = clamp(enemy["hp"] / enemy["max_hp"], 0.0, 1.0)
		var texture: Texture2D = enemy_textures.get(enemy["type"], null)
		var visual_scale: float = float(enemy.get("visual_scale", 1.0))
		var size := Vector2(50, 32)
		match enemy["type"]:
			"saucer":
				size = Vector2(50, 30)
			"cruiser":
				size = Vector2(64, 38)
			"flagship":
				size = Vector2(72, 42)
			"boss":
				size = Vector2(86, 86)
		if texture != null:
			_draw_sprite_centered(texture, pos, size * visual_scale)
		if enemy["type"] == "boss" and bool(enemy.get("attached", false)):
			for i in range(5):
				var tentacle_x := -30 + i * 15
				draw_line(pos + Vector2(tentacle_x, 18), BASE_WORLD_POS + Vector2(tentacle_x * 0.6, -8), Color(0.86, 0.54, 0.96, 0.9), 3.0)

		draw_rect(Rect2(pos + Vector2(-22, -28), Vector2(44, 5)), Color(0.12, 0.08, 0.15, 0.8), true)
		draw_rect(Rect2(pos + Vector2(-21, -27), Vector2(42 * hp_ratio, 3)), Color(0.44, 1.0, 0.64, 1.0), true)


func _draw_sprite_centered(texture: Texture2D, position: Vector2, size: Vector2, modulate: Color = Color.WHITE) -> void:
	if texture == null:
		return
	draw_texture_rect(texture, Rect2(position - size * 0.5, size), false, modulate)


func _draw_rotated_sprite(texture: Texture2D, position: Vector2, size: Vector2, angle: float, modulate: Color = Color.WHITE) -> void:
	if texture == null:
		return
	var texture_size: Vector2 = texture.get_size()
	if texture_size == Vector2.ZERO:
		return
	draw_set_transform(position, angle, size / texture_size)
	draw_texture(texture, -texture_size * 0.5, modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_projectiles() -> void:
	for projectile in player_projectiles:
		var arsenal_id: String = projectile.get("arsenal_id", "machine_gun")
		var color := Color(1.0, 0.86, 0.38, 1.0)
		var radius := 4.0
		if arsenal_id == "missiles":
			color = Color(1.0, 0.52, 0.24, 1.0)
			radius = 5.0
		elif arsenal_id == "emp":
			color = Color(0.48, 0.95, 1.0, 1.0)
		else:
			color = Color(0.32, 0.28, 0.22, 1.0)
			radius = 2.5
		draw_circle(projectile["position"], radius, color)
	for projectile in enemy_projectiles:
		var projectile_kind: String = projectile.get("kind", "laser")
		var color := Color(0.98, 0.33, 0.52, 1.0)
		var radius := 4.0
		if projectile_kind == "ram":
			color = Color(1.0, 0.68, 0.24, 1.0)
			radius = 6.0
		elif projectile_kind == "ray":
			var start: Vector2 = projectile.get("start", projectile["position"])
			var end: Vector2 = projectile.get("end", BASE_WORLD_POS)
			_draw_saucer_beam(start, end)
			continue
		elif projectile_kind == "tentacle":
			color = Color(0.86, 0.54, 0.96, 1.0)
		draw_circle(projectile["position"], radius, color)


func _draw_explosions() -> void:
	if explosion_frames.is_empty():
		return
	for explosion in explosions:
		var frame_index: int = clamp(int(explosion.get("frame", 0)), 0, explosion_frames.size() - 1)
		var frame: Texture2D = explosion_frames[frame_index]
		var size: float = float(explosion.get("size", 48.0))
		_draw_sprite_centered(frame, explosion["position"], Vector2(size, size))


func _draw_saucer_beam(start: Vector2, end: Vector2) -> void:
	var direction := end - start
	var beam_length := direction.length()
	if beam_length <= 1.0:
		return

	var normalized_dir := direction / beam_length
	var half_angle := deg_to_rad(15.0)
	var left_dir := normalized_dir.rotated(-half_angle)
	var right_dir := normalized_dir.rotated(half_angle)
	var left_end := start + left_dir * beam_length
	var right_end := start + right_dir * beam_length

	var cone_points := PackedVector2Array([
		start,
		left_end,
		right_end
	])
	draw_colored_polygon(cone_points, Color(0.6, 0.96, 1.0, 0.18))
	draw_line(start, left_end, Color(0.76, 1.0, 1.0, 0.72), 2.0)
	draw_line(start, right_end, Color(0.76, 1.0, 1.0, 0.72), 2.0)

	var spacing := beam_length / 5.0
	var perpendicular := Vector2(-normalized_dir.y, normalized_dir.x)
	for ring_index in range(1, 5):
		var distance := spacing * ring_index
		var center := start + normalized_dir * distance
		var ring_radius := tan(half_angle) * distance
		var arc_points := PackedVector2Array()
		for segment in range(25):
			var t := float(segment) / 24.0
			var lateral: float = lerpf(-ring_radius, ring_radius, t)
			var depth: float = cos(PI * (t - 0.5)) * ring_radius * 0.18
			arc_points.append(center + perpendicular * lateral + normalized_dir * depth)
		draw_polyline(arc_points, Color(0.72, 0.98, 1.0, 0.45), 1.6)


func _setup_camels() -> void:
	camels.clear()
	for index in range(5):
		camels.append({
			"position": Vector2(140 + index * 210, 438 + (index % 2) * 24),
			"velocity": Vector2(24 + index * 7, 0),
			"wobble": float(index) * 0.9,
			"scale": 0.7 + index * 0.08,
			"alive": true
		})


func _update_camels(delta: float) -> void:
	for camel in camels:
		if not bool(camel.get("alive", true)):
			continue
		var pos: Vector2 = camel["position"]
		var velocity: Vector2 = camel["velocity"]
		var wobble: float = camel["wobble"]
		wobble += delta
		pos.x += velocity.x * delta
		pos.y += sin(wobble * 1.3) * 8.0 * delta + cos(wobble * 0.7) * 6.0 * delta
		velocity.x += sin(wobble * 0.8) * 2.0

		if pos.x > 1320:
			pos.x = -40
		elif pos.x < -60:
			pos.x = 1300

		velocity.x = clamp(velocity.x, 18.0, 42.0)
		camel["position"] = pos
		camel["velocity"] = velocity
		camel["wobble"] = wobble


func _update_explosions(delta: float) -> void:
	if explosion_frames.is_empty():
		explosions.clear()
		return
	var next_explosions: Array[Dictionary] = []
	for explosion in explosions:
		var elapsed: float = float(explosion.get("elapsed", 0.0)) + delta
		var frame_time: float = float(explosion.get("frame_time", 0.06))
		var frame_index := int(floor(elapsed / frame_time))
		if frame_index < explosion_frames.size():
			explosion["elapsed"] = elapsed
			explosion["frame"] = frame_index
			next_explosions.append(explosion)
	explosions = next_explosions


func _setup_weapon_audio_players() -> void:
	weapon_players.clear()
	weapon_players["machine_gun"] = _create_audio_player(machine_gun_sound, 10, -8.0)
	weapon_players["missiles"] = _create_audio_player(missile_launch_sound, 4, -6.0)
	weapon_players["emp"] = _create_audio_player(emp_sound, 4, -10.0)


func _create_audio_player(stream: AudioStream, polyphony: int, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	if stream != null:
		player.stream = stream
	player.bus = "Master"
	player.max_polyphony = polyphony
	player.volume_db = volume_db
	add_child(player)
	return player


func _play_weapon_sound(arsenal_id: String) -> void:
	var player: AudioStreamPlayer = weapon_players.get(arsenal_id, null)
	if player != null and player.stream != null:
		player.play()


func _update_enemies(delta: float) -> void:
	for enemy in alive_enemies:
		var position: Vector2 = enemy["position"]
		var cooldown := float(enemy["cooldown"]) - delta
		var type_name: String = enemy["type"]

		match type_name:
			"saucer":
				_try_absorb_camel(enemy)
				var slot_x := BASE_WORLD_POS.x - 58.0 + fmod(float(enemy["id"] * 23), 116.0)
				var target_pos := Vector2(slot_x, BASE_WORLD_POS.y - 104.0)
				var direction := (target_pos - position)
				if direction.length() > 8.0:
					position += direction.normalized() * float(enemy["speed"]) * delta
				else:
					enemy["anchored"] = true
					_apply_damage_to_base(1.0 * delta)
					_spawn_enemy_beam(position, BASE_WORLD_POS + Vector2(slot_x - BASE_WORLD_POS.x, -12))
			"cruiser":
				var wobble := float(enemy.get("wobble", 0.0)) + delta
				enemy["wobble"] = wobble
				var target_pos := Vector2(BASE_WORLD_POS.x + sin(wobble * 1.7 + float(enemy["id"])) * 180.0, BASE_WORLD_POS.y - 170.0 + cos(wobble * 1.2) * 26.0)
				var direction := target_pos - position
				if direction.length() > 4.0:
					position += direction.normalized() * float(enemy["speed"]) * delta
				if cooldown <= 0.0:
					_spawn_enemy_projectile(enemy, "laser", 3.0)
					cooldown = 1.0 / float(enemy["fire_rate"])
			"flagship":
				var hover_target := Vector2(BASE_WORLD_POS.x + sin(float(enemy["id"]) * 0.7) * 210.0, BASE_WORLD_POS.y - 235.0)
				var direction := hover_target - position
				if direction.length() > 5.0:
					position += direction.normalized() * float(enemy["speed"]) * delta
				if cooldown <= 0.0:
					_spawn_enemy_projectile(enemy, "ram", 10.0)
					cooldown = 5.0
			"boss":
				var boss_target := BASE_WORLD_POS + Vector2(0, -34)
				var direction := boss_target - position
				if direction.length() > 10.0:
					position += direction.normalized() * min(float(enemy["speed"]), 18.0) * delta
				else:
					enemy["attached"] = true
					_apply_damage_to_base(10.0 * delta)
					_spawn_enemy_tentacle_fx(position)

		enemy["position"] = position
		enemy["cooldown"] = cooldown


func _update_arsenal_orientation(delta: float) -> void:
	for arsenal_id in ["machine_gun", "missiles"]:
		var arsenal: Dictionary = arsenals.get(arsenal_id, {})
		if int(arsenal.get("count", 0)) <= 0:
			continue

		var mount := _arsenal_mount_position(arsenal_id)
		var target := _find_primary_target_in_range(float(arsenal.get("range", BASE_FIRE_RANGE_DEFAULT)), mount)
		var current_angle: float = float(arsenal.get("angle", -PI / 2.0))
		if not target.is_empty():
			var desired_angle: float = (target["position"] - mount).angle()
			var rotation_speed := _arsenal_rotation_speed(arsenal_id)
			current_angle = _move_angle_toward(current_angle, desired_angle, rotation_speed * delta)
		arsenal["angle"] = current_angle
		arsenals[arsenal_id] = arsenal


func _update_base_fire(delta: float) -> void:
	if alive_enemies.is_empty():
		return

	for arsenal_id in ["machine_gun", "missiles", "emp"]:
		var arsenal: Dictionary = arsenals.get(arsenal_id, {})
		var count: int = int(arsenal.get("count", 0))
		if count <= 0:
			continue

		var cooldown: float = float(arsenal.get("cooldown", 0.0)) - delta
		if cooldown > 0.0:
			arsenal["cooldown"] = cooldown
			arsenals[arsenal_id] = arsenal
			continue

		var fire_rate: float = float(arsenal.get("fire_rate", 1.0))
		var range_value: float = float(arsenal.get("range", BASE_FIRE_RANGE_DEFAULT))
		var projectile_speed: float = float(arsenal.get("projectile_speed", 400.0))
		var damage: float = float(arsenal.get("damage", 1.0))
		var mount := _arsenal_mount_position(arsenal_id)
		var burst_targets := _find_targets_in_range(count, range_value, mount)
		if burst_targets.is_empty():
			arsenal["cooldown"] = 0.0
			arsenals[arsenal_id] = arsenal
			continue

		var angle: float = float(arsenal.get("angle", -PI / 2.0))
		var fired_any := false
		for target in burst_targets:
			var start := mount
			if arsenal_id != "emp":
				var desired_angle: float = (target["position"] - start).angle()
				if abs(_angle_distance(angle, desired_angle)) > 0.18:
					continue
			player_projectiles.append({
				"position": start,
				"velocity": (target["position"] - start).normalized() * projectile_speed,
				"damage": damage,
				"target_id": target["id"],
				"arsenal_id": arsenal_id
			})
			fired_any = true

		if fired_any:
			_play_weapon_sound(arsenal_id)
		arsenal["cooldown"] = 1.0 / fire_rate
		arsenals[arsenal_id] = arsenal


func _update_projectiles(delta: float) -> void:
	var next_player: Array[Dictionary] = []
	for projectile in player_projectiles:
		var position: Vector2 = projectile["position"] + projectile["velocity"] * delta
		projectile["position"] = position

		var hit := false
		for enemy in alive_enemies:
			if enemy["id"] == projectile["target_id"] and position.distance_to(enemy["position"]) <= 18.0:
				var effective_damage: float = max(float(projectile["damage"]) - float(enemy["armor"]), 1.0)
				enemy["hp"] = max(float(enemy["hp"]) - effective_damage, 0.0)
				combat_score += 1
				if float(enemy["hp"]) <= 0.0:
					combat_score += 10 * int(enemy["rank"])
					_spawn_explosion(enemy["position"], _enemy_explosion_size(enemy["type"]), true)
				hit = true
				break
		if not hit and position.y > -40 and position.y < 760 and position.x > -40 and position.x < 1320:
			next_player.append(projectile)
	player_projectiles = next_player

	var next_enemy: Array[Dictionary] = []
	for projectile in enemy_projectiles:
		var projectile_kind: String = projectile.get("kind", "laser")
		if projectile_kind == "ray" or projectile_kind == "tentacle":
			var ttl: float = float(projectile.get("ttl", 0.0)) - delta
			if ttl > 0.0:
				projectile["ttl"] = ttl
				next_enemy.append(projectile)
			continue

		var position: Vector2 = projectile["position"] + projectile["velocity"] * delta
		projectile["position"] = position
		if position.distance_to(BASE_WORLD_POS) <= BASE_RADIUS:
			_apply_damage_to_base(float(projectile["damage"]))
		elif position.y > -40 and position.y < 760 and position.x > -40 and position.x < 1320:
			next_enemy.append(projectile)
	enemy_projectiles = next_enemy


func _resolve_wave_state() -> void:
	var survivors: Array[Dictionary] = []
	for enemy in alive_enemies:
		if float(enemy["hp"]) > 0.0:
			survivors.append(enemy)
	alive_enemies = survivors

	if house_hp <= 0.0:
		_on_game_over()
		return

	if bool(current_wave_data.get("completed", false)) and alive_enemies.is_empty():
		_on_wave_cleared()


func _update_wave_spawning(delta: float) -> void:
	if current_wave_data.is_empty():
		return

	current_wave_data["elapsed"] = min(float(current_wave_data.get("elapsed", 0.0)) + delta, WAVE_DURATION)
	var elapsed: float = current_wave_data["elapsed"]
	var next_spawn_at: float = current_wave_data.get("next_spawn_at", 0.0)
	var spawn_interval: float = current_wave_data.get("spawn_interval", 1.0)

	while next_spawn_at < WAVE_DURATION and elapsed >= next_spawn_at:
		_spawn_next_wave_enemy()
		next_spawn_at += spawn_interval

	current_wave_data["next_spawn_at"] = next_spawn_at
	current_wave_data["completed"] = elapsed >= WAVE_DURATION and next_spawn_at >= WAVE_DURATION


func _spawn_next_wave_enemy() -> void:
	var spawn_index: int = int(current_wave_data.get("spawned_count", 0))
	var level_number: int = int(current_wave_data.get("level", 1))
	var wave_number: int = int(current_wave_data.get("wave", 1))
	var type_name := _select_enemy_type(level_number, wave_number, spawn_index)
	var start_position := _spawn_position_for_index(spawn_index, next_enemy_id)
	var enemy := _build_enemy(type_name, level_number, wave_number, next_enemy_id, start_position)
	alive_enemies.append(enemy)
	next_enemy_id += 1
	current_wave_data["spawned_count"] = spawn_index + 1
	var roster: Dictionary = current_wave_data.get("roster_spawned", {})
	roster[type_name] = int(roster.get(type_name, 0)) + 1
	current_wave_data["roster_spawned"] = roster


func _apply_damage_to_base(amount: float) -> void:
	var remaining: float = amount
	if dome_hp > 0.0:
		var absorbed: float = min(dome_hp, remaining)
		dome_hp -= absorbed
		remaining -= absorbed
		if absorbed > 0.0:
			dome_flash_timer = 0.22
	if remaining > 0.0:
		house_hp = max(house_hp - remaining, 0.0)
		if house_fx_cooldown <= 0.0:
			house_fx_cooldown = 0.16
			_spawn_explosion(BASE_WORLD_POS + Vector2(0, 26), 72.0, true)


func _spawn_explosion(position: Vector2, size: float, play_sound: bool) -> void:
	explosions.append({
		"position": position,
		"elapsed": 0.0,
		"frame": 0,
		"frame_time": 0.06,
		"size": size
	})
	if play_sound and explosion_player != null:
		if explosion_player.stream == null:
			return
		explosion_player.play()


func _enemy_explosion_size(type_name: String) -> float:
	match type_name:
		"saucer":
			return 42.0
		"cruiser":
			return 54.0
		"flagship":
			return 68.0
		"boss":
			return 96.0
		_:
			return 48.0


func _spawn_enemy_projectile(enemy: Dictionary, projectile_kind: String, damage: float) -> void:
	var start: Vector2 = enemy["position"]
	var direction: Vector2 = (BASE_WORLD_POS - start).normalized()
	var speed := 230.0
	if projectile_kind == "ram":
		speed = 190.0
	enemy_projectiles.append({
		"position": start,
		"velocity": direction * speed,
		"damage": damage,
		"kind": projectile_kind
	})


func _spawn_enemy_beam(start: Vector2, end: Vector2, ttl: float = 0.08) -> void:
	enemy_projectiles.append({
		"position": end,
		"start": start,
		"end": end,
		"ttl": ttl,
		"kind": "ray"
	})


func _spawn_enemy_tentacle_fx(start: Vector2) -> void:
	enemy_projectiles.append({
		"position": BASE_WORLD_POS + Vector2(0, -6),
		"start": start,
		"end": BASE_WORLD_POS + Vector2(0, -6),
		"ttl": 0.12,
		"kind": "tentacle"
	})


func _find_front_enemy_index() -> int:
	var best_index := -1
	var best_distance := INF
	for index in range(alive_enemies.size()):
		var distance: float = alive_enemies[index]["position"].distance_to(BASE_WORLD_POS)
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index


func _find_targets_in_range(max_targets: int, range_value: float, origin: Vector2) -> Array[Dictionary]:
	var indexed_targets := []
	for enemy in alive_enemies:
		var distance: float = enemy["position"].distance_to(origin)
		if distance <= range_value:
			indexed_targets.append({
				"distance": distance,
				"enemy": enemy
			})

	indexed_targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["distance"]) < float(b["distance"])
	)

	var results: Array[Dictionary] = []
	for index in range(min(max_targets, indexed_targets.size())):
		results.append(indexed_targets[index]["enemy"])
	return results


func _find_primary_target_in_range(range_value: float, origin: Vector2) -> Dictionary:
	var targets := _find_targets_in_range(1, range_value, origin)
	if targets.is_empty():
		return {}
	return targets[0]


func _try_absorb_camel(enemy: Dictionary) -> void:
	if bool(enemy.get("camel_absorbed", false)):
		return
	var enemy_pos: Vector2 = enemy["position"]
	for camel in camels:
		if not bool(camel.get("alive", true)):
			continue
		var camel_pos: Vector2 = camel["position"] + Vector2(0, -8)
		var horizontal_distance: float = abs(enemy_pos.x - camel_pos.x)
		var vertical_distance: float = abs(enemy_pos.y - camel_pos.y)
		if horizontal_distance <= 34.0 and vertical_distance <= 26.0:
			_spawn_enemy_beam(enemy_pos, camel_pos, 0.18)
			camel["alive"] = false
			enemy["camel_absorbed"] = true
			enemy["visual_scale"] = float(enemy.get("visual_scale", 1.0)) * 2.0
			enemy["max_hp"] = float(enemy["max_hp"]) * 2.0
			enemy["hp"] = float(enemy["hp"]) * 2.0
			enemy["armor"] = float(enemy["armor"]) * 2.0
			enemy["speed"] = float(enemy["speed"]) * 2.0
			enemy["fire_rate"] = float(enemy["fire_rate"]) * 2.0
			enemy["shot_power"] = float(enemy["shot_power"]) * 2.0
			current_message = "Une soucoupe a absorbe un chameau et a double sa puissance."
			return


func _arsenal_mount_position(arsenal_id: String) -> Vector2:
	match arsenal_id:
		"machine_gun":
			return BASE_WORLD_POS + Vector2(-22, 18)
		"missiles":
			return BASE_WORLD_POS + Vector2(24, 20)
		_:
			return BASE_WORLD_POS + Vector2(0, -40)


func _arsenal_rotation_speed(arsenal_id: String) -> float:
	var level_scale := 1.0 + float(current_level - 1) * 0.12
	match arsenal_id:
		"machine_gun":
			return 2.8 * level_scale
		"missiles":
			return 1.9 * level_scale
		_:
			return 0.0


func _move_angle_toward(current: float, target: float, max_delta: float) -> float:
	var delta := _angle_distance(current, target)
	if abs(delta) <= max_delta:
		return target
	return current + sign(delta) * max_delta


func _angle_distance(from_angle: float, to_angle: float) -> float:
	return wrapf(to_angle - from_angle, -PI, PI)


func _on_wave_cleared() -> void:
	player_projectiles.clear()
	enemy_projectiles.clear()

	if current_level == TOTAL_LEVELS and current_wave == WAVES_PER_LEVEL:
		_on_victory()
		return

	state = STATE_UPGRADE
	pending_upgrade_options = _build_upgrade_options()
	_rebuild_upgrade_buttons()
	current_message = "Fin de vague. Choisissez l'evolution irreversible a appliquer avant la prochaine attaque."
	upgrade_subtitle.text = "Tous les bumps sont disponibles: nombre, puissance ou frequence pour chacun des trois arsenaux."


func _on_game_over() -> void:
	state = STATE_GAME_OVER
	dome_hp = 0.0
	house_hp = 0.0
	alive_enemies.clear()
	player_projectiles.clear()
	enemy_projectiles.clear()
	explosions.clear()
	current_message = "GAME OVER. La maison a ete detruite. Toute nouvelle tentative repart du niveau 1."
	_show_all_overlays()


func _on_victory() -> void:
	state = STATE_VICTORY
	alive_enemies.clear()
	player_projectiles.clear()
	enemy_projectiles.clear()
	explosions.clear()
	current_message = "Victoire totale. Les 11 niveaux ont ete nettoyes en %s." % _format_time(run_time)
	_show_all_overlays()


func _on_start_pressed() -> void:
	_start_new_run()


func _on_restart_pressed() -> void:
	_start_new_run()


func _on_submit_score_pressed() -> void:
	if state != STATE_VICTORY or score_saved:
		return

	var player_name := name_edit.text.strip_edges()
	if player_name.is_empty():
		player_name = "Anonyme"

	var entry := {
		"name": player_name,
		"time": run_time,
		"timestamp": Time.get_datetime_string_from_system(true)
	}
	leaderboard.append(entry)
	leaderboard.sort_custom(_sort_scores_ascending)
	if leaderboard.size() > MAX_LEADERBOARD_ENTRIES:
		leaderboard.resize(MAX_LEADERBOARD_ENTRIES)
	_save_leaderboard()
	score_saved = true
	current_message = "Score enregistre pour %s en %s." % [player_name, _format_time(run_time)]
	_refresh_leaderboard_text()


func _on_upgrade_pressed(index: int) -> void:
	if state != STATE_UPGRADE:
		return
	if index < 0 or index >= pending_upgrade_options.size():
		return

	var upgrade: Dictionary = pending_upgrade_options[index]
	if not bool(upgrade.get("enabled", true)):
		return
	_apply_upgrade(upgrade)
	pending_upgrade_options.clear()
	_rebuild_upgrade_buttons()
	dome_hp = dome_max_hp
	house_hp = house_max_hp
	if current_wave < WAVES_PER_LEVEL:
		current_wave += 1
	else:
		current_level += 1
		current_wave = 1
	current_message = "Arsenal reconfigure: %s. Niveau %d, vague %d imminents." % [upgrade["title"], current_level, current_wave]
	_start_wave(current_level, current_wave)


func _start_new_run() -> void:
	current_level = 1
	current_wave = 1
	run_time = 0.0
	score_saved = false
	combat_score = 0
	pending_upgrade_options.clear()
	_rebuild_upgrade_buttons()
	name_edit.text = ""
	explosions.clear()
	dome_flash_timer = 0.0
	house_fx_cooldown = 0.0

	dome_max_hp = 1000.0
	dome_hp = dome_max_hp
	house_max_hp = 100.0
	house_hp = house_max_hp
	_setup_arsenals()
	show_combat_stats = false
	show_leaderboard = false
	next_enemy_id = 0

	current_message = "Run initialisee. La base sous dome tient le centre du desert. Les vagues restent identiques d'une run a l'autre."
	_start_wave(1, 1)


func _start_wave(level_number: int, wave_number: int) -> void:
	current_wave_data = _build_wave_data(level_number, wave_number)
	alive_enemies.clear()
	player_projectiles.clear()
	enemy_projectiles.clear()
	pending_upgrade_options.clear()
	_rebuild_upgrade_buttons()
	_restore_camels_for_wave()
	for arsenal_id in arsenals.keys():
		var arsenal: Dictionary = arsenals[arsenal_id]
		arsenal["cooldown"] = 0.0
		arsenals[arsenal_id] = arsenal
	state = STATE_FIGHTING


func _build_wave_data(level_number: int, wave_number: int) -> Dictionary:
	var progress := float(wave_number - 1) / float(WAVES_PER_LEVEL - 1)
	var spawn_interval: float = lerp(1.0, 0.2, progress)
	var count: int = int(ceil(WAVE_DURATION / spawn_interval))

	return {
		"count": count,
		"level": level_number,
		"wave": wave_number,
		"spawn_interval": spawn_interval,
		"elapsed": 0.0,
		"next_spawn_at": 0.0,
		"completed": false,
		"spawned_count": 0,
		"roster_spawned": {
			"saucer": 0,
			"cruiser": 0,
			"flagship": 0,
			"boss": 0
		},
		"threat": _wave_threat_label(level_number, wave_number)
	}


func _restore_camels_for_wave() -> void:
	for camel in camels:
		camel["alive"] = true


func _spawn_position_for_index(spawn_index: int, enemy_id: int) -> Vector2:
	var start_x := 120.0 + fmod(float(spawn_index * 67 + enemy_id * 29), 1040.0)
	var start_y := -80.0 - float(spawn_index % 6) * 36.0 - float(int(enemy_id / 8)) * 14.0
	return Vector2(start_x, start_y)


func _select_enemy_type(level_number: int, wave_number: int, spawn_index: int) -> String:
	var roll := int((spawn_index * 17 + wave_number * 9 + level_number * 13) % 100)
	if wave_number == 10 and spawn_index > 0 and spawn_index % max(14 - level_number, 6) == 0:
		return "boss"
	if wave_number >= 8 and roll < min(8 + level_number, 22):
		return "flagship"
	if wave_number >= 7 and roll > 84:
		return "flagship"
	if wave_number >= 4 and roll > 58:
		return "cruiser"
	return "saucer"


func _build_enemy(type_name: String, level_number: int, wave_number: int, enemy_id: int, start_position: Vector2) -> Dictionary:
	var stats := _enemy_template(type_name)
	var scale := 1.0 + (level_number - 1) * 0.22
	return {
		"id": enemy_id,
		"type": type_name,
		"display_name": stats["display_name"],
		"rank": stats["rank"],
		"max_hp": stats["hp"] * scale,
		"hp": stats["hp"] * scale,
		"armor": stats["armor"] + (level_number - 1) * stats["armor_gain"],
		"speed": stats["speed"] + (level_number - 1) * stats["speed_gain"],
		"fire_rate": stats["fire_rate"] + (level_number - 1) * stats["fire_gain"],
		"shot_power": stats["shot_power"] * (1.0 + (level_number - 1) * 0.18),
		"position": start_position,
		"cooldown": randf_range(0.0, 1.2),
		"anchored": false,
		"attached": false,
		"wobble": randf_range(0.0, PI * 2.0),
		"camel_absorbed": false,
		"visual_scale": 1.0
	}


func _enemy_template(type_name: String) -> Dictionary:
	match type_name:
		"saucer":
			return {
				"display_name": "Petites soucoupes",
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
		"cruiser":
			return {
				"display_name": "Croiseurs",
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
		"flagship":
			return {
				"display_name": "Vaisseaux amiraux",
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
		"boss":
			return {
				"display_name": "Boss pieuvres",
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


func _wave_threat_label(level_number: int, wave_number: int) -> String:
	if wave_number == 10 or level_number >= 9:
		return "Boss"
	if wave_number >= 7:
		return "Majeure"
	if wave_number >= 4:
		return "Soutenue"
	return "Faible"


func _setup_arsenals() -> void:
	arsenals = {
		"machine_gun": {
			"title": "Mitraillette",
			"count": 1,
			"damage": 4.68,
			"damage_level": 0,
			"fire_rate": 3.0,
			"fire_rate_level": 0,
			"projectile_speed": 520.0,
			"range": BASE_FIRE_RANGE_DEFAULT,
			"cooldown": 0.0,
			"angle": -PI / 2.0,
			"max_count": 10
		},
		"missiles": {
			"title": "Missiles",
			"count": 0,
			"damage": 14.04,
			"damage_level": 0,
			"fire_rate": 1.0 / 3.0,
			"fire_rate_level": 0,
			"projectile_speed": 320.0,
			"range": BASE_FIRE_RANGE_DEFAULT + 40.0,
			"cooldown": 0.0,
			"angle": -PI / 2.0,
			"max_count": 10
		},
		"emp": {
			"title": "Onde electromagnetique",
			"count": 0,
			"damage": 4.68,
			"damage_level": 0,
			"fire_rate": 1.0 / 3.0,
			"fire_rate_level": 0,
			"projectile_speed": 410.0,
			"range": BASE_FIRE_RANGE_DEFAULT - 40.0,
			"cooldown": 0.0,
			"max_count": 10
		}
	}


func _build_upgrade_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var arsenal_order := ["machine_gun", "missiles", "emp"]
	var upgrade_order := ["count", "damage", "fire_rate"]

	for arsenal_id in arsenal_order:
		for upgrade_kind in upgrade_order:
			options.append(_build_upgrade_option(arsenal_id, upgrade_kind))

	return options


func _build_upgrade_option(arsenal_id: String, upgrade_kind: String) -> Dictionary:
	var arsenal: Dictionary = arsenals.get(arsenal_id, {})
	var title: String = arsenal.get("title", arsenal_id)
	var current_count: int = int(arsenal.get("count", 0))
	var max_count: int = int(arsenal.get("max_count", 10))
	var enabled := true
	var description := ""
	var option_title := ""
	match upgrade_kind:
		"count":
			enabled = current_count < max_count
			option_title = "%s : +1 element" % title
			description = "Nombre %d/10 -> %d/10." % [current_count, min(current_count + 1, max_count)]
		"damage":
			var damage_level: int = int(arsenal.get("damage_level", 0))
			option_title = "%s : puissance de tir" % title
			description = "Niveau %d -> %d." % [damage_level, damage_level + 1]
		_:
			var fire_rate_level: int = int(arsenal.get("fire_rate_level", 0))
			option_title = "%s : frequence de tir" % title
			description = "Niveau %d -> %d." % [fire_rate_level, fire_rate_level + 1]

	return {
		"id": "%s_%s" % [arsenal_id, upgrade_kind],
		"arsenal_id": arsenal_id,
		"kind": upgrade_kind,
		"title": option_title,
		"description": description,
		"enabled": enabled
	}


func _rebuild_upgrade_buttons() -> void:
	for child in upgrade_options_grid.get_children():
		child.queue_free()
	upgrade_buttons.clear()

	for index in range(pending_upgrade_options.size()):
		var option: Dictionary = pending_upgrade_options[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(210, 112)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.icon = _upgrade_icon(option)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.text = "%s\n%s" % [option["title"], option["description"]]
		button.disabled = not bool(option.get("enabled", true))
		button.pressed.connect(_on_upgrade_pressed.bind(index))
		upgrade_options_grid.add_child(button)
		upgrade_buttons.append(button)


func _upgrade_icon(option: Dictionary) -> Texture2D:
	match option.get("arsenal_id", ""):
		"machine_gun":
			return machine_gun_texture
		"missiles":
			return missile_launcher_texture
		"emp":
			return emp_texture
		_:
			return null


func _apply_upgrade(upgrade: Dictionary) -> void:
	var arsenal_id: String = upgrade.get("arsenal_id", "")
	var arsenal: Dictionary = arsenals.get(arsenal_id, {})
	match upgrade.get("kind", ""):
		"count":
			arsenal["count"] = min(int(arsenal.get("count", 0)) + 1, int(arsenal.get("max_count", 10)))
		"damage":
			arsenal["damage"] = float(arsenal.get("damage", 1.0)) * 1.20
			arsenal["damage_level"] = int(arsenal.get("damage_level", 0)) + 1
		"fire_rate":
			arsenal["fire_rate"] = float(arsenal.get("fire_rate", 1.0)) * 1.20
			arsenal["fire_rate_level"] = int(arsenal.get("fire_rate_level", 0)) + 1
	arsenal["cooldown"] = 0.0
	arsenals[arsenal_id] = arsenal


func _update_upgrade_buttons() -> void:
	upgrade_panel.visible = state == STATE_UPGRADE
	for index in range(upgrade_buttons.size()):
		var button := upgrade_buttons[index]
		if index < pending_upgrade_options.size():
			var option: Dictionary = pending_upgrade_options[index]
			button.visible = true
			button.text = "%s\n%s" % [option["title"], option["description"]]
		else:
			button.visible = false


func _update_ui() -> void:
	_update_upgrade_buttons()
	var overlay_allowed := _overlay_allowed()
	var upgrade_visible := state == STATE_UPGRADE
	left_column.visible = overlay_allowed or upgrade_visible
	right_column.visible = overlay_allowed and show_leaderboard
	status_panel.visible = show_combat_stats and not upgrade_visible
	message_panel.visible = show_combat_stats and not upgrade_visible
	control_panel.visible = overlay_allowed
	leaderboard_panel.visible = overlay_allowed and show_leaderboard
	shortcut_hint.visible = overlay_allowed
	shortcut_hint.text = "[S] Stats: %s   [L] Leaderboard: %s" % [
		"ON" if show_combat_stats else "OFF",
		"ON" if show_leaderboard else "OFF"
	]
	run_state_label.text = "Etat: %s" % _state_label()
	timer_label.text = "Temps: %s" % _format_time(run_time)
	level_label.text = "Niveau: %d / %d" % [current_level, TOTAL_LEVELS]
	wave_label.text = "Vague: %d / %d" % [current_wave, WAVES_PER_LEVEL]
	base_label.text = "Dome: %s / %s | Maison: %s / %s | %.1f degats | %.2f tirs/s" % [
		_format_number(dome_hp),
		_format_number(dome_max_hp),
		_format_number(house_hp),
		_format_number(house_max_hp),
		_total_arsenal_damage(),
		_total_arsenal_fire_rate()
	]
	var wave_count := 0
	if current_wave_data.has("count"):
		wave_count = current_wave_data["count"]
	var wave_remaining: float = max(WAVE_DURATION - float(current_wave_data.get("elapsed", 0.0)), 0.0)
	wave_stats_label.text = "Menace: %s | %d spawns | %.1fs restant" % [
		current_wave_data.get("threat", "--"),
		wave_count,
		wave_remaining
	]
	score_label.text = "Score combat: %d" % combat_score
	arsenal_label.text = "Arsenaux: %s" % _arsenal_summary_text()
	roster_label.text = "Composition: %s" % _roster_text()
	message_label.text = current_message
	name_edit.visible = state == STATE_VICTORY and not score_saved
	submit_score_button.visible = state == STATE_VICTORY and not score_saved
	submit_score_button.disabled = score_saved
	start_button.disabled = state == STATE_FIGHTING or state == STATE_UPGRADE
	start_button.visible = state == STATE_IDLE
	restart_button.visible = state != STATE_IDLE


func _state_label() -> String:
	match state:
		STATE_IDLE:
			return "en attente"
		STATE_FIGHTING:
			return "combat en cours"
		STATE_UPGRADE:
			return "choix d'arsenal"
		STATE_GAME_OVER:
			return "game over"
		STATE_VICTORY:
			return "victoire"
		_:
			return state


func _roster_text() -> String:
	if current_wave_data.is_empty():
		return "--"
	var roster: Dictionary = current_wave_data.get("roster_spawned", {})
	return "Spawnes %d/%d | Soucoupes %d | Croiseurs %d | Amiraux %d | Boss %d | Restants %d" % [
		int(current_wave_data.get("spawned_count", 0)),
		int(current_wave_data.get("count", 0)),
		roster.get("saucer", 0),
		roster.get("cruiser", 0),
		roster.get("flagship", 0),
		roster.get("boss", 0),
		alive_enemies.size()
	]


func _arsenal_summary_text() -> String:
	var parts: Array[String] = []
	for arsenal_id in ["machine_gun", "missiles", "emp"]:
		var arsenal: Dictionary = arsenals.get(arsenal_id, {})
		parts.append("%s x%d" % [arsenal.get("title", arsenal_id), int(arsenal.get("count", 0))])
	return " | ".join(parts)


func _total_arsenal_damage() -> float:
	var total := 0.0
	for arsenal_id in arsenals.keys():
		var arsenal: Dictionary = arsenals[arsenal_id]
		total += float(arsenal.get("damage", 0.0)) * float(arsenal.get("count", 0))
	return total


func _total_arsenal_fire_rate() -> float:
	var total := 0.0
	for arsenal_id in arsenals.keys():
		var arsenal: Dictionary = arsenals[arsenal_id]
		total += float(arsenal.get("fire_rate", 0.0)) * float(arsenal.get("count", 0))
	return total


func _refresh_leaderboard_text() -> void:
	if leaderboard.is_empty():
		leaderboard_text.text = "Aucun score enregistre."
		return
	var lines: Array[String] = []
	for index in range(leaderboard.size()):
		var entry := leaderboard[index]
		lines.append("%d. %s - %s" % [index + 1, entry.get("name", "Anonyme"), _format_time(float(entry.get("time", 0.0)))])
	leaderboard_text.text = "\n".join(lines)


func _load_leaderboard() -> void:
	leaderboard.clear()
	if not FileAccess.file_exists(LEADERBOARD_PATH):
		return
	var file := FileAccess.open(LEADERBOARD_PATH, FileAccess.READ)
	if file == null:
		return
	var content := file.get_as_text()
	if content.strip_edges().is_empty():
		return
	var parsed = JSON.parse_string(content)
	if typeof(parsed) != TYPE_ARRAY:
		return
	for item in parsed:
		if typeof(item) == TYPE_DICTIONARY:
			leaderboard.append(item)
	leaderboard.sort_custom(_sort_scores_ascending)
	if leaderboard.size() > MAX_LEADERBOARD_ENTRIES:
		leaderboard.resize(MAX_LEADERBOARD_ENTRIES)


func _save_leaderboard() -> void:
	var file := FileAccess.open(LEADERBOARD_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(leaderboard, "  "))


func _sort_scores_ascending(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("time", 0.0)) < float(b.get("time", 0.0))


func _format_time(value: float) -> String:
	var total_centiseconds := int(round(value * 100.0))
	var minutes := int(total_centiseconds / 6000)
	var seconds := int(total_centiseconds / 100) % 60
	var centiseconds := int(total_centiseconds % 100)
	return "%02d:%02d.%02d" % [minutes, seconds, centiseconds]


func _format_number(value: float) -> String:
	if value >= 100.0:
		return str(int(round(value)))
	return "%.1f" % value


func _overlay_allowed() -> bool:
	return state == STATE_IDLE or state == STATE_GAME_OVER or state == STATE_VICTORY


func _show_all_overlays() -> void:
	show_combat_stats = true
	show_leaderboard = true


func _reset_to_idle() -> void:
	state = STATE_IDLE
	run_time = 0.0
	score_saved = false
	combat_score = 0
	current_level = 1
	current_wave = 1
	current_wave_data = {}
	alive_enemies.clear()
	player_projectiles.clear()
	enemy_projectiles.clear()
	explosions.clear()
	pending_upgrade_options.clear()
	dome_max_hp = 1000.0
	dome_hp = dome_max_hp
	house_max_hp = 100.0
	house_hp = house_max_hp
	_setup_arsenals()
	_rebuild_upgrade_buttons()
	_show_all_overlays()
	next_enemy_id = 0
	dome_flash_timer = 0.0
	house_fx_cooldown = 0.0
	current_message = "Lancez une run pour voir arriver les envahisseurs."
