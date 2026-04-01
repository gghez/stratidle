class_name UpgradeOption
extends RefCounted

var arsenal_id: int = 0
var kind: int = 0
var title: String = ""
var description: String = ""
var enabled: bool = true


func setup(initial_arsenal_id: int, initial_kind: int, option_title: String, option_description: String, is_enabled: bool) -> UpgradeOption:
	arsenal_id = initial_arsenal_id
	kind = initial_kind
	title = option_title
	description = option_description
	enabled = is_enabled
	return self
