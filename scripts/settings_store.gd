class_name SettingsStore
extends RefCounted

const GameConfig = preload("res://scripts/game_config.gd")


static func load_audio_settings() -> Dictionary:
	var defaults: Dictionary = {
		"sounds_volume": GameConfig.DEFAULT_SOUND_VOLUME,
		"music_volume": GameConfig.DEFAULT_MUSIC_VOLUME
	}
	if not FileAccess.file_exists(GameConfig.SETTINGS_PATH):
		return defaults
	var file: FileAccess = FileAccess.open(GameConfig.SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return defaults
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return defaults
	var data: Dictionary = parsed
	return {
		"sounds_volume": clamp(float(data.get("sounds_volume", defaults["sounds_volume"])), 0.0, 1.0),
		"music_volume": clamp(float(data.get("music_volume", defaults["music_volume"])), 0.0, 1.0)
	}


static func save_audio_settings(sounds_volume: float, music_volume: float) -> void:
	var file: FileAccess = FileAccess.open(GameConfig.SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to save audio settings to %s" % GameConfig.SETTINGS_PATH)
		return
	file.store_string(JSON.stringify({
		"sounds_volume": clamp(sounds_volume, 0.0, 1.0),
		"music_volume": clamp(music_volume, 0.0, 1.0)
	}, "  "))
