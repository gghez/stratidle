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
	camel_position.y += sin(wobble * 1.3) * 8.0 * delta + cos(wobble * 0.7) * 6.0 * delta
	velocity.x += sin(wobble * 0.8) * 2.0

	if camel_position.x > 1320.0:
		camel_position.x = -40.0
	elif camel_position.x < -60.0:
		camel_position.x = 1300.0

	velocity.x = clamp(velocity.x, 18.0, 42.0)
	global_position = camel_position
	queue_redraw()


func absorb_anchor_position() -> Vector2:
	return camel_position + Vector2(0, -8)


func _draw() -> void:
	if not alive or CAMEL_TEXTURE == null:
		return
	var draw_size := Vector2(64, 48) * scale_factor
	var draw_color := Color(1.0, 1.0, 1.0, 0.28 + scale_factor * 0.24)
	draw_texture_rect(CAMEL_TEXTURE, Rect2(Vector2(-draw_size.x * 0.5, -6.0 * scale_factor - draw_size.y * 0.5), draw_size), false, draw_color)
