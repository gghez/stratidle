class_name CamelEntity
extends Node2D

static var CAMEL_TEXTURE: Texture2D = preload("res://assets/sprites/camel.svg")

var camel_position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var wobble: float = 0.0
var scale_factor: float = 1.0
var alive: bool = true


func setup(initial_position: Vector2, initial_velocity: Vector2, initial_wobble: float, initial_scale_factor: float) -> void:
	camel_position = initial_position
	velocity = initial_velocity
	wobble = initial_wobble
	scale_factor = initial_scale_factor
	alive = true
	global_position = camel_position
	queue_redraw()


func restore() -> void:
	alive = true
	queue_redraw()


func update_motion(delta: float) -> void:
	if not alive:
		return
	wobble += delta
	camel_position.x += velocity.x * delta
	camel_position.y += sin(wobble * GameConfig.CAMEL_WOBBLE_SIN_FREQ) * GameConfig.CAMEL_WOBBLE_SIN_AMP * delta + cos(wobble * GameConfig.CAMEL_WOBBLE_COS_FREQ) * GameConfig.CAMEL_WOBBLE_COS_AMP * delta
	velocity.x += sin(wobble * GameConfig.CAMEL_DRIFT_FREQ) * GameConfig.CAMEL_DRIFT_AMP

	if camel_position.x > GameConfig.CAMEL_WRAP_RIGHT:
		camel_position.x = GameConfig.CAMEL_WRAP_RESET_LEFT
	elif camel_position.x < GameConfig.CAMEL_WRAP_LEFT:
		camel_position.x = GameConfig.CAMEL_WRAP_RESET_RIGHT

	velocity.x = clamp(velocity.x, GameConfig.CAMEL_SPEED_MIN, GameConfig.CAMEL_SPEED_MAX)
	global_position = camel_position
	queue_redraw()


func absorb_anchor_position() -> Vector2:
	return camel_position + Vector2(0, GameConfig.CAMEL_ANCHOR_OFFSET_Y)


func _draw() -> void:
	if not alive or CAMEL_TEXTURE == null:
		return
	var draw_size: Vector2 = GameConfig.CAMEL_DRAW_BASE_SIZE * scale_factor
	var draw_color := Color(1.0, 1.0, 1.0, GameConfig.CAMEL_DRAW_ALPHA_BASE + scale_factor * GameConfig.CAMEL_DRAW_ALPHA_SCALE)
	draw_texture_rect(CAMEL_TEXTURE, Rect2(Vector2(-draw_size.x * 0.5, GameConfig.CAMEL_DRAW_OFFSET_Y * scale_factor - draw_size.y * 0.5), draw_size), false, draw_color)
