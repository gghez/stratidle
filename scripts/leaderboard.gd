extends RefCounted


static func load_entries(path: String, max_entries: int) -> Array[Dictionary]:
	var leaderboard: Array[Dictionary] = []
	if not FileAccess.file_exists(path):
		return leaderboard
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return leaderboard
	var content := file.get_as_text()
	if content.strip_edges().is_empty():
		return leaderboard
	var parsed = JSON.parse_string(content)
	if typeof(parsed) != TYPE_ARRAY:
		return leaderboard
	for item in parsed:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = item
		if not _is_valid_entry(entry):
			continue
		leaderboard.append(entry)
	leaderboard.sort_custom(sort_scores_descending)
	if leaderboard.size() > max_entries:
		leaderboard.resize(max_entries)
	return leaderboard


static func save_entries(path: String, leaderboard: Array[Dictionary]) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(leaderboard, "  "))


static func sort_scores_descending(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("score", 0)) > int(b.get("score", 0))


static func _is_valid_entry(entry: Dictionary) -> bool:
	if not entry.has("name") or not entry.has("score") or not entry.has("timestamp"):
		return false
	return typeof(entry["name"]) == TYPE_STRING and typeof(entry["timestamp"]) == TYPE_STRING and typeof(entry["score"]) == TYPE_INT
