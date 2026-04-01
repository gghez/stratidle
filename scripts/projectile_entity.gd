class_name ProjectileEntity
extends Node2D

const GameEnums = preload("res://scripts/enums.gd")

static var MACHINE_GUN_BULLET_TEXTURE: Texture2D = preload("res://assets/sprites/machine_gun_bullet.png")
static var MISSILE_PROJECTILE_TEXTURE: Texture2D = preload("res://assets/sprites/missile_projectile.png")

var velocity: Vector2 = Vector2.ZERO
var damage: float = 0.0
var target_id: int = -1
var arsenal_id: int = -1
var kind: int = -1
var ttl: float = 0.0
var start_point: Vector2 = Vector2.ZERO
var end_point: Vector2 = Vector2.ZERO
var visual_scale: float = 1.0


func setup_player(start: Vector2, initial_velocity: Vector2, projectile_damage: float, enemy_target_id: int, source_arsenal_id: int, scale_value: float) -> void:
	global_position = start
	velocity = initial_velocity
	damage = projectile_damage
	target_id = enemy_target_id
	arsenal_id = source_arsenal_id
	visual_scale = scale_value
	queue_redraw()


func setup_enemy(start: Vector2, initial_velocity: Vector2, projectile_damage: float, projectile_kind: int) -> void:
	global_position = start
	velocity = initial_velocity
	damage = projectile_damage
	kind = projectile_kind
	queue_redraw()


func setup_beam(start: Vector2, end: Vector2, beam_ttl: float, beam_kind: int) -> void:
	global_position = end
	start_point = start
	end_point = end
	ttl = beam_ttl
	kind = beam_kind
	queue_redraw()


func advance(delta: float) -> bool:
	if kind == GameEnums.ProjectileKind.RAY or kind == GameEnums.ProjectileKind.TENTACLE or kind == GameEnums.ProjectileKind.LASER:
		ttl = max(ttl - delta, 0.0)
		return ttl > 0.0
	global_position += velocity * delta
	return true


func _draw() -> void:
	if arsenal_id != -1:
		_draw_player_projectile()
	else:
		_draw_enemy_projectile()


func _draw_player_projectile() -> void:
	var angle := velocity.angle()
	if arsenal_id == GameEnums.ArsenalId.MACHINE_GUN and MACHINE_GUN_BULLET_TEXTURE != null:
		_draw_rotated_texture(MACHINE_GUN_BULLET_TEXTURE, Vector2(10, 10) * visual_scale, angle + PI / 2.0)
		return
	if arsenal_id == GameEnums.ArsenalId.MISSILES and MISSILE_PROJECTILE_TEXTURE != null:
		_draw_rotated_texture(MISSILE_PROJECTILE_TEXTURE, Vector2(18, 18) * visual_scale, angle + PI / 2.0)
		return
	var color := Color(0.48, 0.95, 1.0, 1.0)
	var radius := 4.0
	if arsenal_id == GameEnums.ArsenalId.MACHINE_GUN:
		color = Color(0.32, 0.28, 0.22, 1.0)
		radius = 2.5
	elif arsenal_id == GameEnums.ArsenalId.MISSILES:
		color = Color(1.0, 0.52, 0.24, 1.0)
		radius = 5.0
	draw_circle(Vector2.ZERO, radius * visual_scale, color)


func _draw_enemy_projectile() -> void:
	if kind == GameEnums.ProjectileKind.LASER:
		draw_line(Vector2.ZERO, end_point - start_point, Color(1.0, 0.08, 0.08, 1.0), 2.0)
		return
	if kind == GameEnums.ProjectileKind.RAY:
		_draw_saucer_beam(start_point - global_position, Vector2.ZERO)
		return
	if kind == GameEnums.ProjectileKind.TENTACLE:
		draw_circle(Vector2.ZERO, 4.0, Color(0.86, 0.54, 0.96, 1.0))
		return
	var color := Color(0.98, 0.33, 0.52, 1.0)
	var radius := 4.0
	if kind == GameEnums.ProjectileKind.RAM:
		color = Color(1.0, 0.68, 0.24, 1.0)
		radius = 6.0
	draw_circle(Vector2.ZERO, radius, color)


func _draw_rotated_texture(texture: Texture2D, size: Vector2, angle: float) -> void:
	if texture == null:
		return
	var texture_size := texture.get_size()
	if texture_size == Vector2.ZERO:
		return
	draw_set_transform(Vector2.ZERO, angle, size / texture_size)
	draw_texture(texture, -texture_size * 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_saucer_beam(start: Vector2, end: Vector2) -> void:
	var direction := end - start
	var beam_length := direction.length()
	if beam_length <= 1.0:
		return
	var normalized_dir := direction / beam_length
	var half_angle := deg_to_rad(15.0)
	var left_dir := normalized_dir.rotated(-half_angle)
	var right_dir := normalized_dir.rotated(half_angle)
	var left_end := start + left_dir * beam_length
	var right_end := start + right_dir * beam_length
	var cone_points := PackedVector2Array([start, left_end, right_end])
	draw_colored_polygon(cone_points, Color(0.6, 0.96, 1.0, 0.18))
	draw_line(start, left_end, Color(0.76, 1.0, 1.0, 0.72), 2.0)
	draw_line(start, right_end, Color(0.76, 1.0, 1.0, 0.72), 2.0)
	for ring in range(4):
		var t := float(ring + 1) / 5.0
		var center := start.lerp(end, t)
		var ring_radius: float = lerpf(8.0, 24.0, t)
		draw_arc(center, ring_radius, -half_angle, half_angle, 20, Color(0.8, 1.0, 1.0, 0.5), 1.2)
