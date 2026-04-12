## Auto-loaded node that handles global variables
extends Node

const SAVE_FILE_LOCATION := "user://2DVisualNovelDemo.save"

func add_variable(_name: String, value) -> void:
	var data: Dictionary = {}
	if save_file_is_empty(SAVE_FILE_LOCATION):
		write_dictionary_data_to_json(SAVE_FILE_LOCATION, data, _name, value)
	else:
		data = copy_file_data_to_dictionary(SAVE_FILE_LOCATION)
		write_dictionary_data_to_json(SAVE_FILE_LOCATION, data, _name, value)
	return

#Ensures that the file path is pointing to an appropriate location on disk
func path_integrity_checker(path: String):
	if not FileAccess.file_exists(path):
		push_error("Path %s does not exist" % path)
		return false
	else: return true

#Checks if the file has contents to read from
func save_file_is_empty(path: String):
	if path_integrity_checker(path):
		var save_file := FileAccess.open(path, FileAccess.READ)
		if save_file.get_as_text() == "":
			save_file.close()
			return true
		else: 
			save_file.close()
			return false

#writes the data of input dictionary to a save file on disk
func write_dictionary_data_to_json(path: String, data: Dictionary, _name:String, value):
	if _name != "":
		data[_name] = _evaluate(value)
		var save_file := FileAccess.open(path, FileAccess.WRITE)
		var json = JSON.new()
		var error = json.parse(JSON.stringify(data))
		if error != OK:
			printerr(json.get_error_message())
		else:
			print(json.data)
			save_file.store_line(JSON.stringify(json.data))
	else:
		printerr("Null variable name")

#copies the data of a save file on disk as a dictionary
func copy_file_data_to_dictionary(path):
	var save_file := FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(save_file.get_as_text())
	if error != OK:
		printerr(json.get_error_message())
	else:
		return json.data

func get_stored_variables_list() -> Dictionary:
	# Stop if the save file doesn't exist
	if not FileAccess.file_exists(SAVE_FILE_LOCATION):
		return {}

	var save_file = FileAccess.open(SAVE_FILE_LOCATION, FileAccess.READ)
	var save_file_string = save_file.get_as_text()
	var test_json_conv = JSON.new()
	var parse_error = test_json_conv.parse(save_file_string)
	if parse_error != OK:
		print("JSON Parse Error: ", test_json_conv.get_error_message(), " at line ", test_json_conv.get_error_line())
		return {}

	var data: Dictionary = test_json_conv.data

	save_file.close()

	return data


# Used to evaluate the variables' values
func _evaluate(input):
	var script = GDScript.new()
	script.set_source_code("func eval():\n\treturn " + input)
	script.reload()
	var obj = RefCounted.new()
	obj.set_script(script)
	return obj.eval()
