class_name ScreenshotManager
extends RefCounted

var notice_text: String = ""
var notice_timer: float = 0.0


func tick(delta: float) -> void:
	notice_timer = max(notice_timer - delta, 0.0)
	if notice_timer == 0.0:
		notice_text = ""


func show_notice(text: String) -> void:
	notice_text = text
	notice_timer = 30.0


func save_screenshot(viewport: Viewport) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	if image == null or image.is_empty():
		show_notice("Screenshot capture failed.")
		return
	var file_path: String = _preferred_screenshot_directory().path_join("stratidle_%s.png" % _screenshot_timestamp())
	var error: int = image.save_png(file_path)
	show_notice(file_path if error == OK else "Screenshot save failed.")


func _preferred_screenshot_directory() -> String:
	var pictures_dir: String = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	if not pictures_dir.is_empty():
		var screenshots_dir := pictures_dir.path_join("Screenshots")
		var create_error: int = DirAccess.make_dir_recursive_absolute(screenshots_dir)
		if create_error == OK or DirAccess.dir_exists_absolute(screenshots_dir):
			return screenshots_dir
	var fallback_dir := ProjectSettings.globalize_path("user://screenshots")
	DirAccess.make_dir_recursive_absolute(fallback_dir)
	return fallback_dir


func _screenshot_timestamp() -> String:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d_%02d-%02d-%02d" % [int(now.get("year", 1970)), int(now.get("month", 1)), int(now.get("day", 1)), int(now.get("hour", 0)), int(now.get("minute", 0)), int(now.get("second", 0))]
