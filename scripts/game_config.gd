class_name GameConfig
extends RefCounted

const SCREEN_WIDTH: float = 1280.0
const SCREEN_HEIGHT: float = 720.0
const SCREEN_MARGIN: float = 40.0
const OFFSCREEN_LEFT: float = -40.0
const OFFSCREEN_RIGHT: float = SCREEN_WIDTH + SCREEN_MARGIN
const OFFSCREEN_TOP: float = -40.0
const OFFSCREEN_BOTTOM: float = SCREEN_HEIGHT + SCREEN_MARGIN

const TOTAL_LEVELS: int = 11
const WAVES_PER_LEVEL: int = 10
const WAVE_DURATION: float = 30.0
const MAX_LEADERBOARD_ENTRIES: int = 10
const LEADERBOARD_PATH: String = "user://leaderboard.json"
const SETTINGS_PATH: String = "user://settings.json"

const BASE_WORLD_POS: Vector2 = Vector2(640.0, 620.0)
const BASE_RADIUS: float = 95.0
const BASE_FIRE_RANGE_DEFAULT: float = 720.0
const DOME_VISUAL_RADIUS: float = 66.0
const DOME_FLASH_DURATION: float = 0.22
const HOUSE_FX_COOLDOWN: float = 0.16

const COLLISION_DISTANCE: float = 18.0
const ARSENAL_AIM_TOLERANCE: float = 0.18
const MACHINE_GUN_ROTATION_SPEED: float = 2.8
const MISSILE_ROTATION_SPEED: float = 1.9
const ROTATION_LEVEL_SCALE: float = 0.12
const ENEMY_PROJECTILE_SPEED_LASER: float = 230.0
const ENEMY_PROJECTILE_SPEED_RAM: float = 190.0
const CAMEL_ABSORB_RANGE_X: float = 34.0
const CAMEL_ABSORB_RANGE_Y: float = 26.0
const MOUNT_MIN_DISTANCE: float = 28.0
const MOUNT_PLACEMENT_ATTEMPTS: int = 96

const AUDIO_DB_MACHINE_GUN: float = -8.0
const AUDIO_DB_MISSILES: float = -8.0
const AUDIO_DB_EMP: float = -8.0
const AUDIO_DB_EXPLOSION: float = -8.0
const AUDIO_DB_CAMEL_ABSORB: float = -8.0
const AUDIO_DB_MUSIC: float = -14.0

const DEFAULT_SOUND_VOLUME: float = 1.0
const DEFAULT_MUSIC_VOLUME: float = 1.0
