class_name CombatEffects
extends RefCounted

const EnemyEntity = preload("res://scripts/enemy_entity.gd")
const ExplosionEntity = preload("res://scripts/explosion_entity.gd")
const GameEnums = preload("res://scripts/enums.gd")
const ProjectileEntity = preload("res://scripts/projectile_entity.gd")


static func prune_destroyed_enemies(alive_enemies: Array[EnemyEntity]) -> Array[EnemyEntity]:
	var survivors: Array[EnemyEntity] = []
	for enemy in alive_enemies:
		if enemy.hp > 0.0:
			survivors.append(enemy)
		else:
			enemy.queue_free()
	return survivors


static func advance_explosions(explosions: Array[ExplosionEntity], delta: float) -> Array[ExplosionEntity]:
	var next_explosions: Array[ExplosionEntity] = []
	for explosion in explosions:
		if explosion.advance(delta):
			next_explosions.append(explosion)
		else:
			explosion.queue_free()
	return next_explosions


static func spawn_enemy_projectile(projectile_layer: Node2D, enemy_projectiles: Array[ProjectileEntity], enemy: EnemyEntity, projectile_kind: int, damage: float, speed: float, base_world_pos: Vector2) -> void:
	var projectile := ProjectileEntity.new()
	projectile.setup_enemy(enemy.global_position, (base_world_pos - enemy.global_position).normalized() * speed, damage, projectile_kind)
	projectile_layer.add_child(projectile)
	enemy_projectiles.append(projectile)


static func spawn_enemy_beam(projectile_layer: Node2D, enemy_projectiles: Array[ProjectileEntity], start: Vector2, end: Vector2, ttl: float) -> void:
	var projectile := ProjectileEntity.new()
	projectile.setup_beam(start, end, ttl, GameEnums.ProjectileKind.RAY)
	projectile_layer.add_child(projectile)
	enemy_projectiles.append(projectile)


static func spawn_enemy_laser_beam(projectile_layer: Node2D, enemy_projectiles: Array[ProjectileEntity], start: Vector2, end: Vector2) -> void:
	var projectile := ProjectileEntity.new()
	projectile.setup_beam(start, end, 0.3, GameEnums.ProjectileKind.LASER)
	projectile.position = start
	projectile_layer.add_child(projectile)
	enemy_projectiles.append(projectile)


static func spawn_enemy_tentacle_fx(projectile_layer: Node2D, enemy_projectiles: Array[ProjectileEntity], start: Vector2, base_world_pos: Vector2) -> void:
	var projectile := ProjectileEntity.new()
	projectile.setup_beam(start, base_world_pos + Vector2(0, -6), 0.12, GameEnums.ProjectileKind.TENTACLE)
	projectile_layer.add_child(projectile)
	enemy_projectiles.append(projectile)
