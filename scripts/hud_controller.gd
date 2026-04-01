class_name HudController
extends Node

const Arsenal = preload("res://scripts/arsenal.gd")
const GameEnums = preload("res://scripts/enums.gd")
const WaveData = preload("res://scripts/wave_data.gd")

signal start_pressed()
signal restart_pressed()
signal submit_score_pressed()
signal sound_volume_changed(value: float)
signal music_volume_changed(value: float)
signal menu_start_pressed()
signal menu_resume_pressed()
signal menu_settings_pressed()
signal menu_quit_pressed()

var run_state_label: Label
var timer_label: Label
var level_label: Label
var wave_label: Label
var base_label: Label
var wave_stats_label: Label
var score_label: Label
var arsenal_label: Label
var roster_label: Label
var message_label: Label
var start_button: Button
var restart_button: Button
var name_edit: LineEdit
var submit_score_button: Button
var leaderboard_text: RichTextLabel
var left_column: VBoxContainer
var right_column: VBoxContainer
var status_panel: PanelContainer
var message_panel: PanelContainer
var control_panel: PanelContainer
var leaderboard_panel: PanelContainer
var pause_overlay: ColorRect
var settings_panel: PanelContainer
var sound_slider: HSlider
var sound_mute_icon: TextureRect
var music_slider: HSlider
var music_mute_icon: TextureRect
var main_menu_panel: PanelContainer
var menu_resume_button: Button
var shortcut_hint: Label
var screenshot_path_label: Label
var top_score_label: Label


func configure(hud_root: CanvasLayer, mute_texture: Texture2D) -> void:
	run_state_label = hud_root.get_node("HudRoot/Margin/RootRow/LeftColumn/StatusPanel/StatusMargin/StatusVBox/RunStateLabel")
	timer_label = hud_root.get_node("HudRoot/Margin/RootRow/LeftColumn/StatusPanel/StatusMargin/StatusVBox/TimerLabel")
	level_label = hud_root.get_node("HudRoot/Margin/RootRow/LeftColumn/StatusPanel/StatusMargin/StatusVBox/LevelLabel")
	wave_label = hud_root.get_node("HudRoot/Margin/RootRow/LeftColumn/StatusPanel/StatusMargin/StatusVBox/WaveLabel")
	base_label = hud_root.get_node("HudRoot/Margin/RootRow/LeftColumn/StatusPanel/StatusMargin/StatusVBox/BaseLabel")
	wave_stats_label = hud_root.get_node("HudRoot/Margin/RootRow/LeftColumn/StatusPanel/StatusMargin/StatusVBox/WaveStatsLabel")
	score_label = hud_root.get_node("HudRoot/Margin/RootRow/LeftColumn/StatusPanel/StatusMargin/StatusVBox/ScoreLabel")
	arsenal_label = hud_root.get_node("HudRoot/Margin/RootRow/LeftColumn/StatusPanel/StatusMargin/StatusVBox/ArsenalLabel")
	roster_label = hud_root.get_node("HudRoot/Margin/RootRow/LeftColumn/StatusPanel/StatusMargin/StatusVBox/RosterLabel")
	message_label = hud_root.get_node("HudRoot/Margin/RootRow/LeftColumn/MessagePanel/MessageMargin/MessageVBox/MessageLabel")
	start_button = hud_root.get_node("HudRoot/Margin/RootRow/LeftColumn/ControlPanel/ControlMargin/ControlVBox/ButtonRow/StartButton")
	restart_button = hud_root.get_node("HudRoot/Margin/RootRow/LeftColumn/ControlPanel/ControlMargin/ControlVBox/ButtonRow/RestartButton")
	name_edit = hud_root.get_node("HudRoot/Margin/RootRow/LeftColumn/ControlPanel/ControlMargin/ControlVBox/ScoreRow/NameEdit")
	submit_score_button = hud_root.get_node("HudRoot/Margin/RootRow/LeftColumn/ControlPanel/ControlMargin/ControlVBox/ScoreRow/SubmitScoreButton")
	leaderboard_text = hud_root.get_node("HudRoot/Margin/RootRow/RightColumn/LeaderboardPanel/LeaderboardMargin/LeaderboardVBox/LeaderboardText")
	left_column = hud_root.get_node("HudRoot/Margin/RootRow/LeftColumn")
	right_column = hud_root.get_node("HudRoot/Margin/RootRow/RightColumn")
	status_panel = hud_root.get_node("HudRoot/Margin/RootRow/LeftColumn/StatusPanel")
	message_panel = hud_root.get_node("HudRoot/Margin/RootRow/LeftColumn/MessagePanel")
	control_panel = hud_root.get_node("HudRoot/Margin/RootRow/LeftColumn/ControlPanel")
	leaderboard_panel = hud_root.get_node("HudRoot/Margin/RootRow/RightColumn/LeaderboardPanel")
	pause_overlay = hud_root.get_node("HudRoot/PauseOverlay")
	settings_panel = hud_root.get_node("HudRoot/SettingsPanel")
	sound_slider = hud_root.get_node("HudRoot/SettingsPanel/SettingsMargin/SettingsVBox/SoundRow/SoundSlider")
	sound_mute_icon = hud_root.get_node("HudRoot/SettingsPanel/SettingsMargin/SettingsVBox/SoundRow/SoundMuteIcon")
	music_slider = hud_root.get_node("HudRoot/SettingsPanel/SettingsMargin/SettingsVBox/MusicRow/MusicSlider")
	music_mute_icon = hud_root.get_node("HudRoot/SettingsPanel/SettingsMargin/SettingsVBox/MusicRow/MusicMuteIcon")
	main_menu_panel = hud_root.get_node("HudRoot/MainMenuPanel")
	menu_resume_button = hud_root.get_node("HudRoot/MainMenuPanel/MainMenuMargin/MainMenuVBox/MenuResumeButton")
	shortcut_hint = hud_root.get_node("HudRoot/ShortcutHint")
	screenshot_path_label = hud_root.get_node("HudRoot/ScreenshotPathLabel")
	top_score_label = hud_root.get_node("HudRoot/TopScoreLabel")
	sound_mute_icon.texture = mute_texture
	music_mute_icon.texture = mute_texture
	start_button.pressed.connect(func() -> void: start_pressed.emit())
	restart_button.pressed.connect(func() -> void: restart_pressed.emit())
	submit_score_button.pressed.connect(func() -> void: submit_score_pressed.emit())
	sound_slider.value_changed.connect(func(value: float) -> void: sound_volume_changed.emit(value))
	music_slider.value_changed.connect(func(value: float) -> void: music_volume_changed.emit(value))
	hud_root.get_node("HudRoot/MainMenuPanel/MainMenuMargin/MainMenuVBox/MenuStartButton").pressed.connect(func() -> void: menu_start_pressed.emit())
	menu_resume_button.pressed.connect(func() -> void: menu_resume_pressed.emit())
	hud_root.get_node("HudRoot/MainMenuPanel/MainMenuMargin/MainMenuVBox/MenuSettingsButton").pressed.connect(func() -> void: menu_settings_pressed.emit())
	hud_root.get_node("HudRoot/MainMenuPanel/MainMenuMargin/MainMenuVBox/MenuQuitButton").pressed.connect(func() -> void: menu_quit_pressed.emit())


func set_leaderboard_text(text: String) -> void:
	leaderboard_text.text = text


func update_view(data: Dictionary) -> void:
	left_column.visible = bool(data["show_combat_stats"]) or bool(data["overlay_allowed"]) or bool(data["upgrade_visible"])
	right_column.visible = bool(data["show_leaderboard"]) and (bool(data["overlay_allowed"]) or int(data["state"]) == data["fighting_state"])
	status_panel.visible = bool(data["show_combat_stats"]) and not bool(data["upgrade_visible"])
	message_panel.visible = bool(data["show_combat_stats"]) and not bool(data["upgrade_visible"])
	control_panel.visible = bool(data["overlay_allowed"])
	leaderboard_panel.visible = bool(data["show_leaderboard"]) and not bool(data["upgrade_visible"])
	pause_overlay.visible = bool(data["screen_dimmed"])
	settings_panel.visible = bool(data["settings_visible"])
	main_menu_panel.visible = bool(data["main_menu_visible"]) and not bool(data["settings_visible"])
	menu_resume_button.visible = not bool(data["idle_state"])
	shortcut_hint.text = str(data["shortcut_text"])
	_sync_slider(sound_slider, float(data["sound_volume"]) * 100.0)
	_sync_slider(music_slider, float(data["music_volume"]) * 100.0)
	sound_mute_icon.visible = float(data["sound_volume"]) <= 0.0
	music_mute_icon.visible = float(data["music_volume"]) <= 0.0
	screenshot_path_label.visible = not str(data["screenshot_notice"]).is_empty()
	screenshot_path_label.text = str(data["screenshot_notice"])
	run_state_label.text = str(data["run_state"])
	timer_label.text = str(data["timer"])
	level_label.text = str(data["level"])
	wave_label.text = str(data["wave"])
	base_label.text = str(data["base"])
	wave_stats_label.text = str(data["wave_stats"])
	score_label.text = str(data["score"])
	top_score_label.text = str(data["top_score"])
	top_score_label.visible = bool(data["top_score_visible"])
	arsenal_label.text = str(data["arsenal"])
	roster_label.text = str(data["roster"])
	message_label.text = str(data["message"])
	name_edit.visible = bool(data["victory_input_visible"])
	submit_score_button.visible = bool(data["victory_input_visible"])
	submit_score_button.disabled = bool(data["submit_disabled"])
	start_button.disabled = bool(data["start_disabled"])
	start_button.visible = bool(data["start_visible"])
	restart_button.visible = bool(data["restart_visible"])


func player_name() -> String:
	return name_edit.text


func clear_player_name() -> void:
	name_edit.text = ""


func format_time(value: float) -> String:
	var total_centiseconds: int = int(round(value * 100.0))
	return "%02d:%02d.%02d" % [int(total_centiseconds / 6000), int(total_centiseconds / 100) % 60, int(total_centiseconds % 100)]


func format_number(value: float) -> String:
	return str(int(round(value))) if value >= 100.0 else "%.1f" % value


func arsenal_summary_text(arsenals: Array[Arsenal]) -> String:
	var parts: Array[String] = []
	for arsenal in arsenals:
		parts.append("%s x%d" % [arsenal.title, arsenal.count])
	return " | ".join(parts)


func roster_text(wave_data: WaveData, alive_enemy_count: int) -> String:
	if wave_data == null:
		return "--"
	return "Spawnes %d/%d | Soucoupes %d | Croiseurs %d | Amiraux %d | Boss %d | Restants %d" % [
		wave_data.spawned_count,
		wave_data.count,
		int(wave_data.roster_spawned.get(GameEnums.enemy_key(GameEnums.EnemyType.SAUCER), 0)),
		int(wave_data.roster_spawned.get(GameEnums.enemy_key(GameEnums.EnemyType.CRUISER), 0)),
		int(wave_data.roster_spawned.get(GameEnums.enemy_key(GameEnums.EnemyType.FLAGSHIP), 0)),
		int(wave_data.roster_spawned.get(GameEnums.enemy_key(GameEnums.EnemyType.BOSS), 0)),
		alive_enemy_count
	]


func render(
	state: int,
	is_paused: bool,
	show_combat_stats: bool,
	show_leaderboard: bool,
	settings_visible: bool,
	main_menu_visible: bool,
	screenshot_notice: String,
	run_time: float,
	current_level: int,
	current_wave: int,
	total_levels: int,
	total_waves: int,
	dome_hp: float,
	dome_max_hp: float,
	house_hp: float,
	house_max_hp: float,
	total_damage: float,
	total_fire_rate: float,
	wave_data: WaveData,
	combat_score: int,
	arsenals: Array[Arsenal],
	alive_enemy_count: int,
	current_message: String,
	score_saved: bool,
	sound_volume: float,
	music_volume: float,
	fighting_state: int,
	idle_state: int,
	victory_state: int
) -> void:
	var overlay_allowed: bool = state == idle_state or state == GameEnums.GameState.GAME_OVER or state == victory_state
	update_view({
		"show_combat_stats": show_combat_stats,
		"show_leaderboard": show_leaderboard,
		"overlay_allowed": overlay_allowed,
		"upgrade_visible": state == GameEnums.GameState.UPGRADE,
		"screen_dimmed": is_paused or settings_visible or main_menu_visible,
		"settings_visible": settings_visible,
		"main_menu_visible": main_menu_visible,
		"idle_state": state == idle_state,
		"fighting_state": fighting_state,
		"state": state,
		"shortcut_text": "[S] Stats: %s   [L] Leaderboard: %s   [SPACE] Pause: %s   [ESC] Menu   [F12] Screenshot" % ["ON" if show_combat_stats else "OFF", "ON" if show_leaderboard else "OFF", "ON" if is_paused else "OFF"],
		"sound_volume": sound_volume,
		"music_volume": music_volume,
		"screenshot_notice": screenshot_notice,
		"run_state": "Etat: %s" % GameEnums.state_label(state, is_paused),
		"timer": "Temps: %s" % format_time(run_time),
		"level": "Niveau: %d / %d" % [current_level, total_levels],
		"wave": "Vague: %d / %d" % [current_wave, total_waves],
		"base": "Dome: %s / %s | Maison: %s / %s | %.1f degats | %.2f tirs/s" % [format_number(dome_hp), format_number(dome_max_hp), format_number(house_hp), format_number(house_max_hp), total_damage, total_fire_rate],
		"wave_stats": "Menace: %s | %d spawns | %.1fs restant" % [wave_data.threat if wave_data != null else "--", wave_data.count if wave_data != null else 0, max(30.0 - wave_data.elapsed, 0.0) if wave_data != null else 30.0],
		"score": "Score combat: %d" % combat_score,
		"top_score": "+%d pts" % combat_score,
		"top_score_visible": state == fighting_state or state == GameEnums.GameState.UPGRADE or state == victory_state,
		"arsenal": "Arsenaux: %s" % arsenal_summary_text(arsenals),
		"roster": "Composition: %s" % roster_text(wave_data, alive_enemy_count),
		"message": current_message,
		"victory_input_visible": state == victory_state and not score_saved,
		"submit_disabled": score_saved or player_name().strip_edges().length() != 3,
		"start_disabled": state == fighting_state or state == GameEnums.GameState.UPGRADE,
		"start_visible": state == idle_state,
		"restart_visible": state != idle_state
	})


func _sync_slider(slider: HSlider, value: float) -> void:
	if abs(slider.value - value) > 0.01:
		slider.value = value
