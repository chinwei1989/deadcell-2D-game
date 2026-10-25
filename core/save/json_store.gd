class_name JsonStore
## Safe JSON file storage: atomic writes (temp file, then rename) plus one backup copy.
## If the main file is missing or corrupt, read() falls back to the backup.


static func write(path: String, data: Dictionary) -> Error:
	var tmp_path := path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var backup_path := path + ".bak"
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
		var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(backup_path))
		if err != OK:
			return err
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp_path), ProjectSettings.globalize_path(path))


## Returns an empty Dictionary if neither the file nor its backup can be read.
static func read(path: String) -> Dictionary:
	for candidate: String in [path, path + ".bak"]:
		var data := _read_one(candidate)
		if not data.is_empty():
			return data
	return {}


static func _read_one(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
