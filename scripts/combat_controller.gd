class_name CombatController
extends Node

const Arsenal = preload("res://scripts/arsenal.gd")
const CamelEntity = preload("res://scripts/camel_entity.gd")
const CombatEffects = preload("res://scripts/combat_effects.gd")
const CombatSupport = preload("res://scripts/combat_support.gd")
const EnemyEntity = preload("res://scripts/enemy_entity.gd")
const EnemyLogic = preload("res://scripts/enemy.gd")
const ExplosionEntity = preload("res://scripts/explosion_entity.gd")
const GameConfig = preload("res://scripts/game_config.gd")
const GameEnums = preload("res://scripts/enums.gd")
const ProjectileEntity = preload("res://scripts/projectile_entity.gd")

signal enemy_hit()
signal enemy_destroyed(enemy: EnemyEntity)
signal base_damaged(amount: float)
signal camel_absorbed()
signal weapon_fired(arsenal_id: int)
signal explosion_requested()

var enemy_layer: Node2D
var projectile_layer: Node2D
var explosion_layer: Node2D

var alive_enemies: Array[EnemyEntity] = []
var player_projectiles: Array[ProjectileEntity] = []
var enemy_projectiles: Array[ProjectileEntity] = []
var explosions: Array[ExplosionEntity] = []

var dome_max_hp: float = 1000.0
var dome_hp: float = 1000.0
var house_max_hp: float = 100.0
var house_hp: float = 100.0
var dome_flash_timer: float = 0.0
var house_fx_cooldown: float = 0.0


func configure(initial_enemy_layer: Node2D, initial_projectile_layer: Node2D, initial_explosion_layer: Node2D) -> void:
	enemy_layer = initial_enemy_layer
	projectile_layer = initial_projectile_layer
	explosion_layer = initial_explosion_layer

func start_new_run() -> void:
	dome_max_hp = 1000.0
	dome_hp = dome_max_hp
	house_max_hp = 100.0
	house_hp = house_max_hp
	dome_flash_timer = 0.0
	house_fx_cooldown = 0.0
	reset_runtime_entities()

func start_wave() -> void:
	clear_projectiles()

func update(delta: float, arsenals: Array[Arsenal], camels: Array[CamelEntity], current_level: int, base_world_pos: Vector2) -> void:
	dome_flash_timer = max(dome_flash_timer - delta, 0.0)
	house_fx_cooldown = max(house_fx_cooldown - delta, 0.0)
	_update_arsenal_orientation(delta, arsenals, current_level, base_world_pos)
	_update_enemies(delta, camels, base_world_pos)
	_update_base_fire(delta, arsenals, base_world_pos)
	_update_projectiles(delta, base_world_pos)
	alive_enemies = CombatEffects.prune_destroyed_enemies(alive_enemies)
	explosions = CombatEffects.advance_explosions(explosions, delta)

func spawn_enemy(enemy_type: int, level_number: int, wave_number: int, enemy_id: int, start_position: Vector2) -> void:
	var enemy: EnemyEntity = EnemyLogic.build_enemy(enemy_type, level_number, wave_number, enemy_id, start_position)
	enemy_layer.add_child(enemy)
	alive_enemies.append(enemy)

func has_alive_enemies() -> bool:
	return not alive_enemies.is_empty()

func clear_projectiles() -> void:
	CombatSupport.free_nodes(player_projectiles)
	CombatSupport.free_nodes(enemy_projectiles)
	player_projectiles.clear()
	enemy_projectiles.clear()

func reset_runtime_entities() -> void:
	CombatSupport.free_nodes(alive_enemies)
	CombatSupport.free_nodes(explosions)
	clear_projectiles()
	alive_enemies.clear()
	explosions.clear()

func _update_arsenal_orientation(delta: float, arsenals: Array[Arsenal], current_level: int, base_world_pos: Vector2) -> void:
	for arsenal in arsenals:
		if arsenal.id == GameEnums.ArsenalId.EMP or arsenal.count <= 0:
			continue
		var mounts: Array[Vector2] = CombatSupport.arsenal_mount_positions(arsenal, base_world_pos)
		if mounts.is_empty():
			continue
		var target: EnemyEntity = CombatSupport.find_primary_target_in_range(alive_enemies, arsenal.range_value, mounts[0])
		if target == null:
			continue
		var desired_angle: float = (target.global_position - mounts[0]).angle()
		arsenal.angle = CombatSupport.move_angle_toward(arsenal.angle, desired_angle, CombatSupport.arsenal_rotation_speed(arsenal.id, current_level) * delta)

func _update_enemies(delta: float, camels: Array[CamelEntity], base_world_pos: Vector2) -> void:
	for enemy in alive_enemies:
		if enemy.update_spawn_intro(delta):
			continue
		var position: Vector2 = enemy.global_position
		var cooldown: float = enemy.cooldown - delta
		match enemy.enemy_type:
			GameEnums.EnemyType.SAUCER:
				_try_absorb_camel(enemy, camels)
				var slot_x: float = base_world_pos.x - 58.0 + fmod(float(enemy.id * 23), 116.0)
				var target_pos := Vector2(slot_x, base_world_pos.y - 104.0)
				if position.distance_to(target_pos) > 8.0:
					position += (target_pos - position).normalized() * enemy.speed * delta
				else:
					enemy.anchored = true
					_apply_damage_to_base(1.0 * delta, base_world_pos)
					CombatEffects.spawn_enemy_beam(projectile_layer, enemy_projectiles, position, base_world_pos + Vector2(slot_x - base_world_pos.x, -12.0), 0.08)
			GameEnums.EnemyType.CRUISER:
				enemy.wobble += delta
				var cruiser_target := Vector2(base_world_pos.x + sin(enemy.wobble * 1.7 + float(enemy.id)) * 180.0, base_world_pos.y - 170.0 + cos(enemy.wobble * 1.2) * 26.0)
				if position.distance_to(cruiser_target) > 4.0:
					position += (cruiser_target - position).normalized() * enemy.speed * delta
				if cooldown <= 0.0:
					CombatEffects.spawn_enemy_projectile(projectile_layer, enemy_projectiles, enemy, GameEnums.ProjectileKind.LASER, 3.0, GameConfig.ENEMY_PROJECTILE_SPEED_LASER, base_world_pos)
					cooldown = 1.0 / enemy.fire_rate
			GameEnums.EnemyType.FLAGSHIP:
				var flagship_target := Vector2(base_world_pos.x + sin(float(enemy.id) * 0.7) * 210.0, base_world_pos.y - 235.0)
				if position.distance_to(flagship_target) > 5.0:
					position += (flagship_target - position).normalized() * enemy.speed * delta
				if cooldown <= 0.0:
					CombatEffects.spawn_enemy_projectile(projectile_layer, enemy_projectiles, enemy, GameEnums.ProjectileKind.RAM, 10.0, GameConfig.ENEMY_PROJECTILE_SPEED_RAM, base_world_pos)
					cooldown = 5.0
			GameEnums.EnemyType.BOSS:
				var boss_target := base_world_pos + Vector2(0, -34.0)
				if position.distance_to(boss_target) > 10.0:
					position += (boss_target - position).normalized() * min(enemy.speed, 18.0) * delta
				else:
					enemy.attached = true
					_apply_damage_to_base(10.0 * delta, base_world_pos)
					CombatEffects.spawn_enemy_tentacle_fx(projectile_layer, enemy_projectiles, position, base_world_pos)
		enemy.global_position = position
		enemy.cooldown = cooldown
		enemy.queue_redraw()

func _update_base_fire(delta: float, arsenals: Array[Arsenal], base_world_pos: Vector2) -> void:
	if alive_enemies.is_empty():
		return
	for arsenal in arsenals:
		if arsenal.count <= 0:
			continue
		arsenal.cooldown -= delta
		if arsenal.cooldown > 0.0:
			continue
		var mounts: Array[Vector2] = CombatSupport.arsenal_mount_positions(arsenal, base_world_pos)
		var targets: Array[EnemyEntity] = CombatSupport.find_targets_in_range(alive_enemies, mounts.size(), arsenal.range_value, base_world_pos)
		if mounts.is_empty() or targets.is_empty():
			arsenal.cooldown = 0.0
			continue
		var fired_any: bool = false
		for index in range(min(mounts.size(), targets.size())):
			if arsenal.id != GameEnums.ArsenalId.EMP and abs(CombatSupport.angle_distance(arsenal.angle, (targets[index].global_position - mounts[index]).angle())) > GameConfig.ARSENAL_AIM_TOLERANCE:
				continue
			var direction: Vector2 = targets[index].global_position - mounts[index]
			if direction == Vector2.ZERO:
				continue
			var projectile := ProjectileEntity.new()
			projectile.setup_player(mounts[index], direction.normalized() * arsenal.projectile_speed, arsenal.damage, targets[index].id, arsenal.id, arsenal.projectile_scale)
			projectile_layer.add_child(projectile)
			player_projectiles.append(projectile)
			fired_any = true
		if fired_any:
			weapon_fired.emit(arsenal.id)
			arsenal.cooldown = 1.0 / arsenal.fire_rate

func _update_projectiles(delta: float, base_world_pos: Vector2) -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var next_player: Array[ProjectileEntity] = []
	for projectile in player_projectiles:
		projectile.advance(delta)
		var hit: bool = false
		for enemy in alive_enemies:
			if enemy.id == projectile.target_id and projectile.global_position.distance_to(enemy.global_position) <= GameConfig.COLLISION_DISTANCE:
				enemy_hit.emit()
				if enemy.apply_damage(projectile.damage):
					enemy_destroyed.emit(enemy)
					_spawn_explosion(enemy.global_position, EnemyLogic.enemy_explosion_size(enemy.enemy_type), true)
				hit = true
				break
		if not hit and CombatSupport.is_on_screen(projectile.global_position, viewport_size):
			next_player.append(projectile)
		else:
			projectile.queue_free()
	player_projectiles = next_player
	var next_enemy: Array[ProjectileEntity] = []
	for projectile in enemy_projectiles:
		if not projectile.advance(delta):
			projectile.queue_free()
		elif projectile.global_position.distance_to(base_world_pos) <= GameConfig.BASE_RADIUS:
			_apply_damage_to_base(projectile.damage, base_world_pos)
			projectile.queue_free()
		elif CombatSupport.is_on_screen(projectile.global_position, viewport_size):
			next_enemy.append(projectile)
		else:
			projectile.queue_free()
	enemy_projectiles = next_enemy

func _apply_damage_to_base(amount: float, base_world_pos: Vector2) -> void:
	var remaining: float = amount
	if dome_hp > 0.0:
		var absorbed: float = min(dome_hp, remaining)
		dome_hp -= absorbed
		remaining -= absorbed
		if absorbed > 0.0:
			dome_flash_timer = GameConfig.DOME_FLASH_DURATION
			base_damaged.emit(absorbed)
	if remaining > 0.0:
		house_hp = max(house_hp - remaining, 0.0)
		base_damaged.emit(remaining)
		if house_fx_cooldown <= 0.0:
			house_fx_cooldown = GameConfig.HOUSE_FX_COOLDOWN
			_spawn_explosion(base_world_pos + Vector2(0, 26), 72.0, true)

func _spawn_explosion(position: Vector2, size: float, play_sound: bool) -> void:
	var explosion := ExplosionEntity.new()
	explosion.setup(position, size)
	explosion_layer.add_child(explosion)
	explosions.append(explosion)
	if play_sound:
		explosion_requested.emit()

func _try_absorb_camel(enemy: EnemyEntity, camels: Array[CamelEntity]) -> void:
	if enemy.camel_absorbed:
		return
	for camel in camels:
		if not camel.alive:
			continue
		var camel_pos: Vector2 = camel.absorb_anchor_position()
		if abs(enemy.global_position.x - camel_pos.x) <= GameConfig.CAMEL_ABSORB_RANGE_X and abs(enemy.global_position.y - camel_pos.y) <= GameConfig.CAMEL_ABSORB_RANGE_Y:
			camel.alive = false
			camel.queue_redraw()
			CombatEffects.spawn_enemy_beam(projectile_layer, enemy_projectiles, enemy.global_position, camel_pos, 0.18)
			enemy.apply_camel_absorb_boost()
			camel_absorbed.emit()
			return
