extends Node2D

const Arsenal = preload("res://scripts/arsenal.gd")
const ArsenalLayout = preload("res://scripts/arsenal_layout.gd")
const CamelEntity = preload("res://scripts/camel_entity.gd")
const CombatController = preload("res://scripts/combat_controller.gd")
const GameConfig = preload("res://scripts/game_config.gd")
const GameEnums = preload("res://scripts/enums.gd")
const HudController = preload("res://scripts/hud_controller.gd")
const LeaderboardStore = preload("res://scripts/leaderboard.gd")
const ScreenshotManager = preload("res://scripts/screenshot_manager.gd")
const UpgradeController = preload("res://scripts/upgrade_controller.gd")
const UpgradeOption = preload("res://scripts/upgrade_option.gd")
const WaveData = preload("res://scripts/wave_data.gd")
const WaveManager = preload("res://scripts/wave_manager.gd")
const AudioManagerScript = preload("res://scripts/audio_manager.gd")

signal wave_started(level: int, wave: int)
signal wave_cleared()
signal game_over()
signal victory()

const HOUSE_TEXTURE: Texture2D = preload("res://assets/sprites/base_house.svg")
const MACHINE_GUN_TEXTURE: Texture2D = preload("res://assets/sprites/machine_gun.svg")
const MISSILE_TEXTURE: Texture2D = preload("res://assets/sprites/missile_launcher.svg")
const EMP_TEXTURE: Texture2D = preload("res://assets/sprites/emp.svg")
const MUTE_TEXTURE: Texture2D = preload("res://assets/sprites/mute.svg")

@onready var world_layer: Node2D = $World
@onready var enemy_layer: Node2D = $World/EnemyLayer
@onready var projectile_layer: Node2D = $World/ProjectileLayer
@onready var explosion_layer: Node2D = $World/ExplosionLayer
@onready var hud_layer: CanvasLayer = $HUD

var camel_layer: Node2D
var combat_controller: CombatController
var hud_controller: HudController
var upgrade_controller: UpgradeController
var screenshot_manager: ScreenshotManager = ScreenshotManager.new()

var state: int = GameEnums.GameState.IDLE
var current_level: int = 1
var current_wave: int = 1
var current_wave_data: WaveData = null
var run_time: float = 0.0
var combat_score: int = 0
var score_saved: bool = false
var current_message: String = "Lancez une run pour voir arriver les envahisseurs."
var show_combat_stats: bool = true
var show_leaderboard: bool = true
var is_paused: bool = false
var main_menu_visible: bool = true
var next_enemy_id: int = 0

var arsenals: Array[Arsenal] = []
var camels: Array[CamelEntity] = []
var pending_upgrade_options: Array[UpgradeOption] = []
var leaderboard: Array[Dictionary] = []

func _ready() -> void:
	camel_layer = Node2D.new()
	camel_layer.name = "CamelLayer"
	world_layer.add_child(camel_layer)
	world_layer.move_child(camel_layer, 0)
	combat_controller = CombatController.new()
	hud_controller = HudController.new()
	upgrade_controller = UpgradeController.new()
	add_child(combat_controller)
	add_child(hud_controller)
	add_child(upgrade_controller)
	combat_controller.configure(enemy_layer, projectile_layer, explosion_layer)
	hud_controller.configure(hud_layer, MUTE_TEXTURE)
	upgrade_controller.configure(
		hud_layer.get_node("HudRoot/Margin/RootRow/LeftColumn/UpgradePanel"),
		hud_layer.get_node("HudRoot/Margin/RootRow/LeftColumn/UpgradePanel/UpgradeMargin/UpgradeVBox/UpgradeSubtitle"),
		hud_layer.get_node("HudRoot/Margin/RootRow/LeftColumn/UpgradePanel/UpgradeMargin/UpgradeVBox/UpgradeScroll/UpgradeOptionsGrid"),
		MACHINE_GUN_TEXTURE,
		MISSILE_TEXTURE,
		EMP_TEXTURE
	)
	_connect_signals()
	leaderboard = LeaderboardStore.load_entries(GameConfig.LEADERBOARD_PATH, GameConfig.MAX_LEADERBOARD_ENTRIES)
	_setup_camels()
	_reset_to_idle()

func _process(delta: float) -> void:
	screenshot_manager.tick(delta)
	if is_paused:
		queue_redraw()
		_update_ui()
		return
	for camel in camels:
		camel.update_motion(delta)
	if state == GameEnums.GameState.FIGHTING:
		run_time += delta
		_update_wave_spawning(delta)
		combat_controller.update(delta, arsenals, camels, current_level, GameConfig.BASE_WORLD_POS)
		if combat_controller.house_hp <= 0.0:
			_on_game_over()
		elif current_wave_data != null and current_wave_data.completed and not combat_controller.has_alive_enemies():
			_on_wave_cleared()
	queue_redraw()
	_update_ui()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
	if event.keycode == KEY_ESCAPE:
		_toggle_main_menu()
	elif event.keycode == KEY_SPACE:
		_toggle_pause()
	elif event.keycode == KEY_F12:
		screenshot_manager.save_screenshot(get_viewport())
	elif event.keycode == KEY_S:
		show_combat_stats = not show_combat_stats
	elif event.keycode == KEY_L:
		show_leaderboard = not show_leaderboard
	_update_ui()
	get_viewport().set_input_as_handled()

func _draw() -> void:
	_draw_background(get_viewport_rect().size)
	_draw_base()

func _draw_background(viewport_size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.92, 0.74, 0.44, 1.0), true)
	draw_rect(Rect2(0, 0, viewport_size.x, viewport_size.y * 0.56), Color(0.76, 0.88, 0.98, 1.0), true)
	draw_colored_polygon(PackedVector2Array([Vector2(0, 420), Vector2(140, 392), Vector2(300, 408), Vector2(460, 372), Vector2(660, 402), Vector2(840, 380), Vector2(1040, 414), Vector2(GameConfig.SCREEN_WIDTH, 396), Vector2(GameConfig.SCREEN_WIDTH, GameConfig.SCREEN_HEIGHT), Vector2(0, GameConfig.SCREEN_HEIGHT)]), Color(0.84, 0.63, 0.33, 1.0))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 520), Vector2(180, 500), Vector2(360, 542), Vector2(620, 512), Vector2(880, 548), Vector2(1160, 524), Vector2(GameConfig.SCREEN_WIDTH, 550), Vector2(GameConfig.SCREEN_WIDTH, GameConfig.SCREEN_HEIGHT), Vector2(0, GameConfig.SCREEN_HEIGHT)]), Color(0.91, 0.71, 0.38, 1.0))


func _draw_base() -> void:
	var base_pos: Vector2 = GameConfig.BASE_WORLD_POS
	draw_circle(base_pos + Vector2(0, 56), GameConfig.BASE_RADIUS + 26, Color(0.72, 0.57, 0.29, 1.0))
	draw_rect(Rect2(base_pos + Vector2(-56, 44), Vector2(112, 12)), Color(0.32, 0.23, 0.17, 1.0), true)
	draw_rect(Rect2(base_pos + Vector2(-44, -8), Vector2(88, 72)), Color(0.55, 0.36, 0.19, 1.0), true)
	_draw_sprite_centered(HOUSE_TEXTURE, base_pos + Vector2(0, 24), Vector2(120, 120))
	if combat_controller.dome_hp > 0.0:
		draw_circle(base_pos + Vector2(0, -4), GameConfig.DOME_VISUAL_RADIUS, Color(0.53, 0.78, 0.95, 0.22))
		draw_arc(base_pos + Vector2(0, -4), GameConfig.DOME_VISUAL_RADIUS, PI, TAU, 48, Color(0.7, 0.93, 1.0, 0.75), 3.0)
		if combat_controller.dome_flash_timer > 0.0:
			var flash_alpha: float = min(0.45, combat_controller.dome_flash_timer * 2.4)
			draw_circle(base_pos + Vector2(0, -4), GameConfig.DOME_VISUAL_RADIUS, Color(1.0, 0.18, 0.12, flash_alpha))
			draw_arc(base_pos + Vector2(0, -4), GameConfig.DOME_VISUAL_RADIUS, PI, TAU, 48, Color(1.0, 0.4, 0.32, min(0.95, flash_alpha + 0.2)), 4.0)
	draw_rect(Rect2(base_pos + Vector2(-80, -108), Vector2(160, 10)), Color(0.18, 0.12, 0.08, 0.8), true)
	draw_rect(Rect2(base_pos + Vector2(-78, -106), Vector2(156 * _hp_ratio(combat_controller.dome_hp, combat_controller.dome_max_hp), 6)), Color(0.36, 0.84, 1.0, 1.0), true)
	draw_rect(Rect2(base_pos + Vector2(-80, -94), Vector2(160, 10)), Color(0.18, 0.12, 0.08, 0.8), true)
	draw_rect(Rect2(base_pos + Vector2(-78, -92), Vector2(156 * _hp_ratio(combat_controller.house_hp, combat_controller.house_max_hp), 6)), Color(0.98, 0.76, 0.36, 1.0), true)
	for arsenal_id in [GameEnums.ArsenalId.MACHINE_GUN, GameEnums.ArsenalId.MISSILES, GameEnums.ArsenalId.EMP]:
		_draw_arsenal_mount(arsenal_id)

func _draw_arsenal_mount(arsenal_id: int) -> void:
	var arsenal: Arsenal = _get_arsenal(arsenal_id)
	if arsenal == null or arsenal.count <= 0:
		return
	for mount in ArsenalLayout.mount_positions(arsenal):
		if arsenal_id == GameEnums.ArsenalId.MACHINE_GUN:
			_draw_rotated_sprite(MACHINE_GUN_TEXTURE, mount, Vector2(44, 44), arsenal.angle + PI / 2.0)
		elif arsenal_id == GameEnums.ArsenalId.MISSILES:
			_draw_rotated_sprite(MISSILE_TEXTURE, mount, Vector2(52, 52), arsenal.angle + PI / 2.0)
		else:
			_draw_sprite_centered(EMP_TEXTURE, mount, Vector2(38, 38))


func _start_new_run() -> void:
	main_menu_visible = false
	is_paused = false
	state = GameEnums.GameState.FIGHTING
	current_level = 1
	current_wave = 1
	current_wave_data = null
	run_time = 0.0
	combat_score = 0
	score_saved = false
	next_enemy_id = 0
	current_message = "Run initialisee. La base sous dome tient le centre du desert. Les vagues restent identiques d'une run a l'autre."
	hud_controller.clear_player_name()
	_setup_arsenals()
	combat_controller.start_new_run()
	_start_wave(1, 1)


func _start_wave(level_number: int, wave_number: int) -> void:
	current_level = level_number
	current_wave = wave_number
	current_wave_data = WaveManager.build_wave_data(level_number, wave_number, GameConfig.WAVES_PER_LEVEL, GameConfig.WAVE_DURATION)
	combat_controller.reset_runtime_entities()
	combat_controller.start_wave()
	for camel in camels:
		camel.restore()
	for arsenal in arsenals:
		arsenal.cooldown = 0.0
	pending_upgrade_options.clear()
	upgrade_controller.clear_options()
	state = GameEnums.GameState.FIGHTING
	wave_started.emit(level_number, wave_number)


func _update_wave_spawning(delta: float) -> void:
	if current_wave_data == null:
		return
	current_wave_data.elapsed = min(current_wave_data.elapsed + delta, GameConfig.WAVE_DURATION)
	while current_wave_data.next_spawn_at < GameConfig.WAVE_DURATION and current_wave_data.elapsed >= current_wave_data.next_spawn_at:
		_spawn_next_wave_enemy()
		current_wave_data.next_spawn_at += current_wave_data.spawn_interval
	current_wave_data.completed = current_wave_data.elapsed >= GameConfig.WAVE_DURATION and current_wave_data.next_spawn_at >= GameConfig.WAVE_DURATION


func _spawn_next_wave_enemy() -> void:
	var enemy_type: int = WaveManager.select_enemy_type(current_wave_data.level, current_wave_data.wave, current_wave_data.spawned_count)
	combat_controller.spawn_enemy(enemy_type, current_wave_data.level, current_wave_data.wave, next_enemy_id, WaveManager.spawn_position_for_index(current_wave_data.spawned_count, next_enemy_id))
	current_wave_data.spawned_count += 1
	current_wave_data.roster_spawned[GameEnums.enemy_key(enemy_type)] = int(current_wave_data.roster_spawned.get(GameEnums.enemy_key(enemy_type), 0)) + 1
	next_enemy_id += 1


func _on_wave_cleared() -> void:
	wave_cleared.emit()
	if current_level == GameConfig.TOTAL_LEVELS and current_wave == GameConfig.WAVES_PER_LEVEL:
		_on_victory()
		return
	state = GameEnums.GameState.UPGRADE
	current_message = "Fin de vague. Choisissez l'evolution irreversible a appliquer avant la prochaine attaque."
	pending_upgrade_options = upgrade_controller.build_options(arsenals)
	upgrade_controller.set_options(pending_upgrade_options)
	upgrade_controller.update_visibility(true)


func _on_game_over() -> void:
	state = GameEnums.GameState.GAME_OVER
	main_menu_visible = false
	is_paused = false
	combat_controller.reset_runtime_entities()
	current_message = "GAME OVER. La maison a ete detruite. Toute nouvelle tentative repart du niveau 1."
	show_combat_stats = true
	show_leaderboard = true
	game_over.emit()


func _on_victory() -> void:
	state = GameEnums.GameState.VICTORY
	main_menu_visible = false
	is_paused = false
	combat_controller.reset_runtime_entities()
	current_message = "Victoire totale. Les 11 niveaux ont ete nettoyes en %s." % hud_controller.format_time(run_time)
	show_combat_stats = true
	show_leaderboard = true
	victory.emit()


func _toggle_pause() -> void:
	if state != GameEnums.GameState.FIGHTING and state != GameEnums.GameState.UPGRADE:
		return
	if main_menu_visible:
		return
	is_paused = not is_paused


func _toggle_main_menu() -> void:
	if main_menu_visible or hud_layer.get_node("HudRoot/SettingsPanel").visible:
		main_menu_visible = false
		hud_layer.get_node("HudRoot/SettingsPanel").visible = false
		is_paused = false
	else:
		main_menu_visible = true
		hud_layer.get_node("HudRoot/SettingsPanel").visible = false
		is_paused = state == GameEnums.GameState.FIGHTING or state == GameEnums.GameState.UPGRADE


func _setup_camels() -> void:
	for camel in camels:
		camel.queue_free()
	camels.clear()
	for index in range(5):
		var camel := CamelEntity.new()
		camel.setup(Vector2(140 + index * 210, 438 + (index % 2) * 24), Vector2(24 + index * 7, 0), float(index) * 0.9, 0.7 + index * 0.08)
		camel_layer.add_child(camel)
		camels.append(camel)


func _setup_arsenals() -> void:
	arsenals = [
		Arsenal.new().setup(GameEnums.ArsenalId.MACHINE_GUN, GameEnums.arsenal_title(GameEnums.ArsenalId.MACHINE_GUN), 1, 10, 4.68, 3.0, 520.0, GameConfig.BASE_FIRE_RANGE_DEFAULT),
		Arsenal.new().setup(GameEnums.ArsenalId.MISSILES, GameEnums.arsenal_title(GameEnums.ArsenalId.MISSILES), 0, 10, 14.04, 1.0 / 3.0, 320.0, GameConfig.BASE_FIRE_RANGE_DEFAULT + 40.0),
		Arsenal.new().setup(GameEnums.ArsenalId.EMP, GameEnums.arsenal_title(GameEnums.ArsenalId.EMP), 0, 10, 4.68, 1.0 / 3.0, 410.0, GameConfig.BASE_FIRE_RANGE_DEFAULT - 40.0)
	]
	for arsenal in arsenals:
		ArsenalLayout.sync_mounts(arsenal)


func _update_ui() -> void:
	upgrade_controller.update_visibility(state == GameEnums.GameState.UPGRADE)
	hud_controller.set_leaderboard_text(_leaderboard_text())
	hud_controller.render(state, is_paused, show_combat_stats, show_leaderboard, hud_layer.get_node("HudRoot/SettingsPanel").visible, main_menu_visible, screenshot_manager.notice_text, run_time, current_level, current_wave, GameConfig.TOTAL_LEVELS, GameConfig.WAVES_PER_LEVEL, combat_controller.dome_hp, combat_controller.dome_max_hp, combat_controller.house_hp, combat_controller.house_max_hp, ArsenalLayout.total_damage(arsenals), ArsenalLayout.total_fire_rate(arsenals), current_wave_data, combat_score, arsenals, combat_controller.alive_enemies.size(), current_message, score_saved, _audio_manager().get_sound_volume(), _audio_manager().get_music_volume(), GameEnums.GameState.FIGHTING, GameEnums.GameState.IDLE, GameEnums.GameState.VICTORY)


func _connect_signals() -> void:
	hud_controller.start_pressed.connect(_start_new_run)
	hud_controller.restart_pressed.connect(_start_new_run)
	hud_controller.submit_score_pressed.connect(_on_submit_score_pressed)
	hud_controller.sound_volume_changed.connect(func(value: float) -> void: _audio_manager().set_sound_volume(value / 100.0))
	hud_controller.music_volume_changed.connect(func(value: float) -> void: _audio_manager().set_music_volume(value / 100.0))
	hud_controller.menu_start_pressed.connect(_start_new_run)
	hud_controller.menu_resume_pressed.connect(func() -> void: main_menu_visible = false; hud_layer.get_node("HudRoot/SettingsPanel").visible = false; is_paused = false)
	hud_controller.menu_settings_pressed.connect(func() -> void: main_menu_visible = false; hud_layer.get_node("HudRoot/SettingsPanel").visible = true; is_paused = true)
	hud_controller.menu_quit_pressed.connect(func() -> void: get_tree().quit())
	upgrade_controller.option_selected.connect(_on_upgrade_selected)
	combat_controller.enemy_hit.connect(func() -> void: combat_score += 1)
	combat_controller.enemy_destroyed.connect(func(enemy: EnemyEntity) -> void: combat_score += 10 * enemy.rank)
	combat_controller.camel_absorbed.connect(func() -> void: _audio_manager().play_camel_absorb(); current_message = "Une soucoupe a absorbe un chameau et a double sa puissance.")
	combat_controller.weapon_fired.connect(func(arsenal_id: int) -> void: _audio_manager().play_weapon(arsenal_id))
	combat_controller.explosion_requested.connect(func() -> void: _audio_manager().play_explosion())


func _on_submit_score_pressed() -> void:
	if state != GameEnums.GameState.VICTORY or score_saved:
		return
	var player_name: String = hud_controller.player_name().strip_edges().to_upper().substr(0, 3)
	if player_name.length() != 3:
		current_message = "Entrez un nom de 3 lettres pour enregistrer la victoire."
		return
	leaderboard.append({"name": player_name, "time": run_time, "timestamp": Time.get_datetime_string_from_system(true)})
	leaderboard.sort_custom(LeaderboardStore.sort_scores_ascending)
	if leaderboard.size() > GameConfig.MAX_LEADERBOARD_ENTRIES:
		leaderboard.resize(GameConfig.MAX_LEADERBOARD_ENTRIES)
	LeaderboardStore.save_entries(GameConfig.LEADERBOARD_PATH, leaderboard)
	score_saved = true
	current_message = "Score enregistre pour %s en %s." % [player_name, hud_controller.format_time(run_time)]


func _on_upgrade_selected(index: int) -> void:
	if state != GameEnums.GameState.UPGRADE or index < 0 or index >= pending_upgrade_options.size():
		return
	var option: UpgradeOption = pending_upgrade_options[index]
	if not option.enabled:
		return
	upgrade_controller.apply_upgrade(arsenals, option)
	ArsenalLayout.sync_mounts(_get_arsenal(option.arsenal_id))
	combat_controller.dome_hp = combat_controller.dome_max_hp
	combat_controller.house_hp = combat_controller.house_max_hp
	current_message = "Arsenal reconfigure: %s. Niveau %d, vague %d imminents." % [option.title, current_level + int(current_wave == GameConfig.WAVES_PER_LEVEL), 1 if current_wave == GameConfig.WAVES_PER_LEVEL else current_wave + 1]
	_start_wave(current_level + int(current_wave == GameConfig.WAVES_PER_LEVEL), 1 if current_wave == GameConfig.WAVES_PER_LEVEL else current_wave + 1)


func _reset_to_idle() -> void:
	_setup_arsenals()
	combat_controller.start_new_run()
	combat_controller.reset_runtime_entities()
	state = GameEnums.GameState.IDLE
	current_level = 1
	current_wave = 1
	current_wave_data = null
	run_time = 0.0
	combat_score = 0
	score_saved = false
	main_menu_visible = true
	is_paused = false
	show_combat_stats = true
	show_leaderboard = true
	current_message = "Lancez une run pour voir arriver les envahisseurs."
	upgrade_controller.clear_options()
	_update_ui()


func _leaderboard_text() -> String:
	if leaderboard.is_empty():
		return "Aucun score enregistre."
	var lines: Array[String] = []
	for index in range(leaderboard.size()):
		lines.append("%d. %s - %s" % [index + 1, leaderboard[index].get("name", "Anonyme"), hud_controller.format_time(float(leaderboard[index].get("time", 0.0)))])
	return "\n".join(lines)


func _get_arsenal(arsenal_id: int) -> Arsenal:
	for arsenal in arsenals:
		if arsenal.id == arsenal_id:
			return arsenal
	return null


func _draw_sprite_centered(texture: Texture2D, position: Vector2, size: Vector2, modulate: Color = Color.WHITE) -> void:
	if texture != null:
		draw_texture_rect(texture, Rect2(position - size * 0.5, size), false, modulate)


func _draw_rotated_sprite(texture: Texture2D, position: Vector2, size: Vector2, angle: float, modulate: Color = Color.WHITE) -> void:
	if texture == null or texture.get_size() == Vector2.ZERO:
		return
	draw_set_transform(position, angle, size / texture.get_size())
	draw_texture(texture, -texture.get_size() * 0.5, modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _hp_ratio(current_hp: float, max_hp: float) -> float:
	return clamp(current_hp / max(max_hp, 1.0), 0.0, 1.0)


func _audio_manager() -> AudioManagerScript:
	return get_node("/root/AudioManager") as AudioManagerScript
