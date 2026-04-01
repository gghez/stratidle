class_name Arsenal
extends RefCounted

const GameEnums = preload("res://scripts/enums.gd")

var id: int = GameEnums.ArsenalId.MACHINE_GUN
var title: String = ""
var count: int = 0
var max_count: int = 10
var damage: float = 0.0
var damage_level: int = 0
var fire_rate: float = 0.0
var fire_rate_level: int = 0
var projectile_scale: float = 1.0
var projectile_speed: float = 0.0
var range_value: float = 0.0
var cooldown: float = 0.0
var angle: float = -PI / 2.0
var mount_offsets: Array[Vector2] = []


func setup(
	arsenal_id: int,
	arsenal_title: String,
	initial_count: int,
	initial_max_count: int,
	initial_damage: float,
	initial_fire_rate: float,
	initial_projectile_speed: float,
	initial_range_value: float
) -> Arsenal:
	id = arsenal_id
	title = arsenal_title
	count = initial_count
	max_count = initial_max_count
	damage = initial_damage
	fire_rate = initial_fire_rate
	projectile_speed = initial_projectile_speed
	range_value = initial_range_value
	return self


func apply_count_upgrade() -> void:
	count = min(count + 1, max_count)


func apply_damage_upgrade() -> void:
	damage *= 1.10
	damage_level += 1
	projectile_scale *= 1.10
	projectile_speed *= 1.10


func apply_fire_rate_upgrade() -> void:
	fire_rate *= 1.20
	fire_rate_level += 1
