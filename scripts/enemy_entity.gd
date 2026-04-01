class_name EnemyEntity
extends Node2D

const GameEnums = preload("res://scripts/enums.gd")

static var TEXTURES := {
	GameEnums.EnemyType.SAUCER: preload("res://assets/sprites/saucer.svg"),
	GameEnums.EnemyType.CRUISER: preload("res://assets/sprites/cruiser.svg"),
	GameEnums.EnemyType.FLAGSHIP: preload("res://assets/sprites/flagship.svg"),
	GameEnums.EnemyType.BOSS: preload("res://assets/sprites/boss.svg")
}

var id: int = 0
var enemy_type: int = GameEnums.EnemyType.SAUCER
var display_name: String = ""
var rank: int = 0
var max_hp: float = 0.0
var hp: float = 0.0
var armor: float = 0.0
var speed: float = 0.0
var fire_rate: float = 0.0
var shot_power: float = 0.0
var cooldown: float = 0.0
var anchored: bool = false
var attached: bool = false
var wobble: float = 0.0
var camel_absorbed: bool = false
var visual_scale: float = 1.0
var target_visual_scale: float = 1.0
var spawn_intro_active: bool = false
var spawn_intro_elapsed: float = 0.0
var spawn_intro_duration: float = 1.0
var spawn_intro_origin: Vector2 = Vector2.ZERO
var spawn_intro_target: Vector2 = Vector2.ZERO


func setup(
	enemy_id: int,
	enemy_type_name: int,
	enemy_display_name: String,
	enemy_rank: int,
	enemy_max_hp: float,
	enemy_hp: float,
	enemy_armor: float,
	enemy_speed: float,
	enemy_fire_rate: float,
	enemy_shot_power: float,
	start_position: Vector2,
	initial_cooldown: float,
	initial_wobble: float,
	initial_visual_scale: float,
	initial_target_visual_scale: float,
	initial_spawn_intro_active: bool,
	initial_spawn_intro_elapsed: float,
	initial_spawn_intro_duration: float,
	initial_spawn_intro_origin: Vector2,
	initial_spawn_intro_target: Vector2
) -> void:
	id = enemy_id
	enemy_type = enemy_type_name
	display_name = enemy_display_name
	rank = enemy_rank
	max_hp = enemy_max_hp
	hp = enemy_hp
	armor = enemy_armor
	speed = enemy_speed
	fire_rate = enemy_fire_rate
	shot_power = enemy_shot_power
	cooldown = initial_cooldown
	anchored = false
	attached = false
	wobble = initial_wobble
	camel_absorbed = false
	visual_scale = initial_visual_scale
	target_visual_scale = initial_target_visual_scale
	spawn_intro_active = initial_spawn_intro_active
	spawn_intro_elapsed = initial_spawn_intro_elapsed
	spawn_intro_duration = initial_spawn_intro_duration
	spawn_intro_origin = initial_spawn_intro_origin
	spawn_intro_target = initial_spawn_intro_target
	global_position = start_position
	queue_redraw()


func update_spawn_intro(delta: float) -> bool:
	if not spawn_intro_active:
		return false
	var duration: float = max(spawn_intro_duration, 0.01)
	spawn_intro_elapsed = min(spawn_intro_elapsed + delta, duration)
	var progress: float = spawn_intro_elapsed / duration
	global_position = spawn_intro_origin.lerp(spawn_intro_target, progress)
	visual_scale = lerp(0.0, target_visual_scale, progress)
	if progress >= 1.0:
		spawn_intro_active = false
		global_position = spawn_intro_target
		visual_scale = target_visual_scale
	queue_redraw()
	return true


func apply_camel_absorb_boost() -> void:
	camel_absorbed = true
	target_visual_scale *= 2.0
	visual_scale *= 2.0
	max_hp *= 2.0
	hp *= 2.0
	armor *= 2.0
	speed *= 2.0
	fire_rate *= 2.0
	shot_power *= 2.0
	queue_redraw()


func apply_damage(amount: float) -> bool:
	var effective_damage: float = max(amount - armor, 1.0)
	hp = max(hp - effective_damage, 0.0)
	queue_redraw()
	return hp <= 0.0


func _draw() -> void:
	var texture: Texture2D = TEXTURES.get(enemy_type, null)
	var size := Vector2(50, 32)
	match enemy_type:
		GameEnums.EnemyType.SAUCER:
			size = Vector2(50, 30)
		GameEnums.EnemyType.CRUISER:
			size = Vector2(64, 38)
		GameEnums.EnemyType.FLAGSHIP:
			size = Vector2(72, 42)
		GameEnums.EnemyType.BOSS:
			size = Vector2(86, 86)
	if texture != null:
		draw_texture_rect(texture, Rect2(-size * visual_scale * 0.5, size * visual_scale), false)
	if enemy_type == GameEnums.EnemyType.BOSS and attached:
		for i in range(5):
			var tentacle_x := -30 + i * 15
			draw_line(Vector2(tentacle_x, 18), Vector2(tentacle_x * 0.6, 54), Color(0.86, 0.54, 0.96, 0.9), 3.0)
	var hp_ratio := 0.0
	if max_hp > 0.0:
		hp_ratio = clamp(hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(Vector2(-22, -28), Vector2(44, 5)), Color(0.12, 0.08, 0.15, 0.8), true)
	draw_rect(Rect2(Vector2(-21, -27), Vector2(42 * hp_ratio, 3)), Color(0.44, 1.0, 0.64, 1.0), true)
