class_name GameEnums
extends RefCounted

enum GameState { IDLE, FIGHTING, UPGRADE, GAME_OVER, VICTORY }
enum EnemyType { SAUCER, CRUISER, FLAGSHIP, BOSS }
enum ArsenalId { MACHINE_GUN, MISSILES, EMP }
enum UpgradeKind { COUNT, DAMAGE, FIRE_RATE }
enum ProjectileKind { LASER, RAM, RAY, TENTACLE }


static func state_label(state: int, is_paused: bool) -> String:
	match state:
		GameState.IDLE:
			return "en attente"
		GameState.FIGHTING:
			return "en pause" if is_paused else "combat en cours"
		GameState.UPGRADE:
			return "choix d'arsenal"
		GameState.GAME_OVER:
			return "game over"
		GameState.VICTORY:
			return "victoire"
		_:
			return "inconnu"


static func enemy_key(enemy_type: int) -> String:
	match enemy_type:
		EnemyType.SAUCER:
			return "saucer"
		EnemyType.CRUISER:
			return "cruiser"
		EnemyType.FLAGSHIP:
			return "flagship"
		EnemyType.BOSS:
			return "boss"
		_:
			return "unknown"


static func enemy_name(enemy_type: int) -> String:
	match enemy_type:
		EnemyType.SAUCER:
			return "Petites soucoupes"
		EnemyType.CRUISER:
			return "Croiseurs"
		EnemyType.FLAGSHIP:
			return "Vaisseaux amiraux"
		EnemyType.BOSS:
			return "Boss pieuvres"
		_:
			return "Inconnu"


static func arsenal_key(arsenal_id: int) -> String:
	match arsenal_id:
		ArsenalId.MACHINE_GUN:
			return "machine_gun"
		ArsenalId.MISSILES:
			return "missiles"
		ArsenalId.EMP:
			return "emp"
		_:
			return "unknown"


static func arsenal_title(arsenal_id: int) -> String:
	match arsenal_id:
		ArsenalId.MACHINE_GUN:
			return "Mitraillette"
		ArsenalId.MISSILES:
			return "Missiles"
		ArsenalId.EMP:
			return "Onde electromagnetique"
		_:
			return "Inconnu"


static func upgrade_kind_label(upgrade_kind: int) -> String:
	match upgrade_kind:
		UpgradeKind.COUNT:
			return "nombre"
		UpgradeKind.DAMAGE:
			return "puissance de tir"
		UpgradeKind.FIRE_RATE:
			return "frequence de tir"
		_:
			return "inconnu"
