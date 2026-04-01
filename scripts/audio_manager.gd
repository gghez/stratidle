extends Node

const GameConfig = preload("res://scripts/game_config.gd")
const GameEnums = preload("res://scripts/enums.gd")
const SettingsStore = preload("res://scripts/settings_store.gd")

var machine_gun_sound: AudioStream
var missile_launch_sound: AudioStream
var emp_sound: AudioStream
var explosion_sound: AudioStream
var camel_absorb_sound: AudioStream
var background_music: AudioStream

var explosion_player: AudioStreamPlayer
var camel_absorb_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var weapon_players: Dictionary = {}

var sounds_volume: float = GameConfig.DEFAULT_SOUND_VOLUME
var music_volume: float = GameConfig.DEFAULT_MUSIC_VOLUME


func _ready() -> void:
	var settings: Dictionary = SettingsStore.load_audio_settings()
	sounds_volume = float(settings.get("sounds_volume", GameConfig.DEFAULT_SOUND_VOLUME))
	music_volume = float(settings.get("music_volume", GameConfig.DEFAULT_MUSIC_VOLUME))
	_load_streams()
	explosion_player = _create_audio_player(explosion_sound, 6, GameConfig.AUDIO_DB_EXPLOSION)
	camel_absorb_player = _create_audio_player(camel_absorb_sound, 1, GameConfig.AUDIO_DB_CAMEL_ABSORB)
	music_player = _create_audio_player(background_music, 1, GameConfig.AUDIO_DB_MUSIC)
	music_player.finished.connect(_on_music_finished)
	weapon_players[GameEnums.ArsenalId.MACHINE_GUN] = _create_audio_player(machine_gun_sound, 10, GameConfig.AUDIO_DB_MACHINE_GUN)
	weapon_players[GameEnums.ArsenalId.MISSILES] = _create_audio_player(missile_launch_sound, 4, GameConfig.AUDIO_DB_MISSILES)
	weapon_players[GameEnums.ArsenalId.EMP] = _create_audio_player(emp_sound, 4, GameConfig.AUDIO_DB_EMP)
	_apply_audio_settings()


func play_weapon(arsenal_id: int) -> void:
	var player: AudioStreamPlayer = weapon_players.get(arsenal_id, null)
	if player != null and sounds_volume > 0.0 and player.stream != null:
		player.play()


func play_explosion() -> void:
	if explosion_player != null and sounds_volume > 0.0 and explosion_player.stream != null:
		explosion_player.play()


func play_camel_absorb() -> void:
	if camel_absorb_player != null and sounds_volume > 0.0 and camel_absorb_player.stream != null:
		camel_absorb_player.play()


func set_sound_volume(value: float) -> void:
	sounds_volume = clamp(value, 0.0, 1.0)
	_apply_audio_settings()
	SettingsStore.save_audio_settings(sounds_volume, music_volume)


func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	_apply_audio_settings()
	SettingsStore.save_audio_settings(sounds_volume, music_volume)


func get_sound_volume() -> float:
	return sounds_volume


func get_music_volume() -> float:
	return music_volume


func _load_streams() -> void:
	machine_gun_sound = load("res://assets/audio/machine_gun.ogg")
	missile_launch_sound = load("res://assets/audio/missile_launch.ogg")
	emp_sound = load("res://assets/audio/emp.ogg")
	explosion_sound = load("res://assets/audio/explosion.ogg")
	camel_absorb_sound = load("res://assets/audio/camel_absorb.ogg")
	background_music = load("res://assets/audio/psychedelic_loop.ogg")


func _create_audio_player(stream: AudioStream, polyphony: int, base_volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	if AudioServer.get_bus_index("Master") == -1:
		push_warning("Master audio bus not found")
	else:
		player.bus = "Master"
	player.max_polyphony = polyphony
	player.set_meta("base_volume_db", base_volume_db)
	add_child(player)
	return player


func _apply_audio_settings() -> void:
	for player in weapon_players.values():
		_set_player_volume(player, sounds_volume)
	_set_player_volume(explosion_player, sounds_volume)
	_set_player_volume(camel_absorb_player, sounds_volume)
	_set_player_volume(music_player, music_volume)
	if music_player == null or music_player.stream == null:
		return
	if music_volume > 0.0 and not music_player.playing:
		music_player.play()
	elif music_volume <= 0.0 and music_player.playing:
		music_player.stop()


func _set_player_volume(player: AudioStreamPlayer, volume_ratio: float) -> void:
	if player == null:
		return
	var base_volume_db: float = float(player.get_meta("base_volume_db", 0.0))
	player.volume_db = base_volume_db + linear_to_db(volume_ratio) if volume_ratio > 0.0 else -80.0


func _on_music_finished() -> void:
	if music_volume > 0.0 and music_player != null and music_player.stream != null:
		music_player.play()
