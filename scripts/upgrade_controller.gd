class_name UpgradeController
extends Node

const Arsenal = preload("res://scripts/arsenal.gd")
const GameEnums = preload("res://scripts/enums.gd")
const UpgradeOption = preload("res://scripts/upgrade_option.gd")

signal option_selected(index: int)

var upgrade_panel: PanelContainer
var upgrade_subtitle: Label
var upgrade_options_grid: GridContainer
var machine_gun_texture: Texture2D
var missile_texture: Texture2D
var emp_texture: Texture2D

var pending_upgrade_options: Array[UpgradeOption] = []
var upgrade_buttons: Array[Button] = []


func configure(panel: PanelContainer, subtitle_label: Label, grid: GridContainer, machine_gun_icon: Texture2D, missile_icon: Texture2D, emp_icon: Texture2D) -> void:
	upgrade_panel = panel
	upgrade_subtitle = subtitle_label
	upgrade_options_grid = grid
	machine_gun_texture = machine_gun_icon
	missile_texture = missile_icon
	emp_texture = emp_icon


func build_options(arsenals: Array[Arsenal]) -> Array[UpgradeOption]:
	var options: Array[UpgradeOption] = []
	for arsenal_id in [GameEnums.ArsenalId.MACHINE_GUN, GameEnums.ArsenalId.MISSILES, GameEnums.ArsenalId.EMP]:
		var arsenal: Arsenal = _find_arsenal(arsenals, arsenal_id)
		if arsenal == null:
			continue
		options.append(_build_upgrade_option(arsenal, GameEnums.UpgradeKind.COUNT))
		options.append(_build_upgrade_option(arsenal, GameEnums.UpgradeKind.DAMAGE))
		options.append(_build_upgrade_option(arsenal, GameEnums.UpgradeKind.FIRE_RATE))
	return options


func set_options(options: Array[UpgradeOption]) -> void:
	pending_upgrade_options = options
	_rebuild_upgrade_buttons()


func clear_options() -> void:
	pending_upgrade_options.clear()
	_rebuild_upgrade_buttons()


func apply_upgrade(arsenals: Array[Arsenal], option: UpgradeOption) -> void:
	var arsenal: Arsenal = _find_arsenal(arsenals, option.arsenal_id)
	if arsenal == null:
		return
	match option.kind:
		GameEnums.UpgradeKind.COUNT:
			arsenal.apply_count_upgrade()
		GameEnums.UpgradeKind.DAMAGE:
			arsenal.apply_damage_upgrade()
		GameEnums.UpgradeKind.FIRE_RATE:
			arsenal.apply_fire_rate_upgrade()
	arsenal.cooldown = 0.0


func update_visibility(is_visible: bool) -> void:
	upgrade_panel.visible = is_visible
	if is_visible:
		upgrade_subtitle.text = "Tous les bumps sont disponibles: nombre, puissance ou frequence pour chacun des trois arsenaux."


func _build_upgrade_option(arsenal: Arsenal, upgrade_kind: int) -> UpgradeOption:
	var enabled: bool = true
	var option_title: String = "%s : %s" % [arsenal.title, GameEnums.upgrade_kind_label(upgrade_kind)]
	var description: String = ""
	match upgrade_kind:
		GameEnums.UpgradeKind.COUNT:
			enabled = arsenal.count < arsenal.max_count
			option_title = "%s : +1 element" % arsenal.title
			description = "Nombre %d/10 -> %d/10." % [arsenal.count, min(arsenal.count + 1, arsenal.max_count)]
		GameEnums.UpgradeKind.DAMAGE:
			description = "Niveau %d -> %d." % [arsenal.damage_level, arsenal.damage_level + 1]
		GameEnums.UpgradeKind.FIRE_RATE:
			description = "Niveau %d -> %d." % [arsenal.fire_rate_level, arsenal.fire_rate_level + 1]
	return UpgradeOption.new().setup(arsenal.id, upgrade_kind, option_title, description, enabled)


func _rebuild_upgrade_buttons() -> void:
	for child in upgrade_options_grid.get_children():
		child.queue_free()
	upgrade_buttons.clear()
	for index in range(pending_upgrade_options.size()):
		var option: UpgradeOption = pending_upgrade_options[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(210, 112)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.icon = _upgrade_icon(option)
		button.text = "%s\n%s" % [option.title, option.description]
		button.disabled = not option.enabled
		button.pressed.connect(_on_option_pressed.bind(index))
		upgrade_options_grid.add_child(button)
		upgrade_buttons.append(button)


func _upgrade_icon(option: UpgradeOption) -> Texture2D:
	match option.arsenal_id:
		GameEnums.ArsenalId.MACHINE_GUN:
			return machine_gun_texture
		GameEnums.ArsenalId.MISSILES:
			return missile_texture
		GameEnums.ArsenalId.EMP:
			return emp_texture
		_:
			return null


func _find_arsenal(arsenals: Array[Arsenal], arsenal_id: int) -> Arsenal:
	for arsenal in arsenals:
		if arsenal.id == arsenal_id:
			return arsenal
	return null


func _on_option_pressed(index: int) -> void:
	option_selected.emit(index)
