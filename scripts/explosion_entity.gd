class_name ExplosionEntity
extends Node2D

static var FRAMES: Array[Texture2D] = [
	preload("res://assets/effects/explosion-01.png"),
	preload("res://assets/effects/explosion-02.png"),
	preload("res://assets/effects/explosion-03.png"),
	preload("res://assets/effects/explosion-04.png"),
	preload("res://assets/effects/explosion-05.png")
]

var elapsed := 0.0
var frame_time := 0.06
var size := 48.0


func setup(explosion_position: Vector2, explosion_size: float) -> void:
	global_position = explosion_position
	size = explosion_size
	queue_redraw()


func advance(delta: float) -> bool:
	elapsed += delta
	var frame_index := int(floor(elapsed / frame_time))
	if frame_index >= FRAMES.size():
		return false
	queue_redraw()
	return true


func _draw() -> void:
	if FRAMES.is_empty():
		return
	var frame_index: int = clampi(int(floor(elapsed / frame_time)), 0, FRAMES.size() - 1)
	var texture: Texture2D = FRAMES[frame_index]
	if texture == null:
		return
	var draw_size: Vector2 = Vector2(size, size)
	draw_texture_rect(texture, Rect2(-draw_size * 0.5, draw_size), false)
