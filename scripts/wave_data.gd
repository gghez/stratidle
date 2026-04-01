class_name WaveData
extends RefCounted

var count: int = 0
var level: int = 1
var wave: int = 1
var spawn_interval: float = 1.0
var elapsed: float = 0.0
var next_spawn_at: float = 0.0
var completed: bool = false
var spawned_count: int = 0
var roster_spawned: Dictionary = {}
var threat: String = ""


func setup(
	initial_count: int,
	level_number: int,
	wave_number: int,
	initial_spawn_interval: float,
	initial_threat: String
) -> WaveData:
	count = initial_count
	level = level_number
	wave = wave_number
	spawn_interval = initial_spawn_interval
	threat = initial_threat
	roster_spawned = {
		"saucer": 0,
		"cruiser": 0,
		"flagship": 0,
		"boss": 0
	}
	return self
