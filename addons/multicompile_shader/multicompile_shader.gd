@tool
class_name MulticompileShader
extends Shader

@export_tool_button("Update Variants") var update_variants_button := update_variants

## Each entry is an option that can be defined in the shader.
## Entries will be modified to CAPITALIZED_SNAKE_CASE format as you type.
## You can make an enum using commas (,).
## First text before the comma (,) is the property name of the enum.
## Enum options are prefixed by the enum name.
## In the inspector, an enums first option is always empty, meaning nothing will be defined.
## There musn't be name collisions.
@export var options: PackedStringArray: set = set_options

@export_group("Resulting Property List")

var proplist: Array[Dictionary]
var proplist_dict: Dictionary[String, Dictionary]

func _get_property_list() -> Array[Dictionary]:
	return proplist

func set_options(value: PackedStringArray) -> void:
	options = value
	if options.has(""): return
	
	var size := options.size()
	var new_options: PackedStringArray
	var new_proplist: Array[Dictionary]
	var new_proplist_dict: Dictionary[String, Dictionary]
	new_options.resize(size)
	new_proplist.resize(size)
	
	for i in size:
		var define := sanitize(options[i])
		var defines := define.split(",")
		
		new_options[i] = define
		
		if defines.size() == 1: # bool
			new_proplist[i] = { "name": define, "type": TYPE_BOOL, "usage": PROPERTY_USAGE_EDITOR }
			new_proplist_dict[define] = new_proplist[i]
		else: # enum
			new_proplist[i] = { "name": defines[0], "type": TYPE_STRING, "usage": PROPERTY_USAGE_EDITOR, "hint": PROPERTY_HINT_ENUM,
				"hint_string": define.trim_prefix(defines[0] + ",")
			}
			new_proplist_dict[defines[0]] = new_proplist[i]
	
	# TODO dupe check
	
	options = new_options
	proplist = new_proplist
	proplist_dict = new_proplist_dict

func get_shader(defines: PackedStringArray) -> Shader:
	if !is_path_valid(): return null
	
	defines = defines.duplicate()
	defines.sort()
	
	var res_name_ext := resource_path.get_file()
	var res_name := res_name_ext.trim_suffix("." + res_name_ext.get_extension())
	var path := resource_path.trim_suffix(res_name_ext) + res_name + "@" + "@".join(defines) + ".tres"
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path)
	
	var shader := Shader.new()
	shader.code = get_variant_code(defines)
	shader.set_meta(&"_defines", defines)
	
	#var err := ResourceSaver.save(shader, path) # saves as a sub/local resource wtf??
	#if err != OK:
		#push_error("MulticompileShader Error: Failed to variant shader file to disk. " + resource_path + ", " + error_string(err))
		#return null
	shader.take_over_path(path)
	if shader.resource_local_to_scene || shader.resource_path.is_empty():
		push_error("MulticompileShader Error: Variant shader somehow ended up as a sub/local resource? " + resource_path)
	return shader

func get_variant_code(defines: PackedStringArray) -> String:
	var result := ""
	for define in defines:
		result += "#define " + define + "\n"
	result += "\n" + code
	return result

func sanitize(input: String) -> String:
	return input.to_snake_case().validate_node_name().to_upper().validate_filename()

func update_variants() -> void:
	if !is_path_valid(): return
	var folder := resource_path.trim_suffix(resource_path.get_file())
	var dir := DirAccess.open(folder)
	if !dir:
		push_error("MulticompileShader Error: Cannot open folder. " + resource_path + ", " + error_string(DirAccess.get_open_error()))
		return
	dir.include_hidden = false
	dir.include_navigational = false
	dir.list_dir_begin()
	var file_name_ext := dir.get_next()
	while !file_name_ext.is_empty():
		if dir.current_is_dir(): continue
		file_name_ext = dir.get_next()
		var ext := file_name_ext.get_extension()
		var name := file_name_ext.get_file().trim_suffix(ext)
		if ext != "tres": continue
		var full_path := folder + file_name_ext
		var variant := load(full_path) as Shader
		if variant == self: continue
		if !variant.has_meta(&"_defines"):
			push_error("MulticompileShader Error: Variant shader file has to contain the relative metadata. " + full_path)
			continue
		var defines: Variant = variant.get_meta(&"_defines")
		if defines is PackedStringArray:
			var new_code := get_variant_code(defines as PackedStringArray)
			variant.code = new_code
			if variant.code != new_code:
				push_error("MulticompileShader Error: Shader variant file could not be saved because it is open in the Shader Editor tab. Please close the file. " + full_path)
		else:
			push_error("MulticompileShader Error: Variant shader file contains invalid metadata. " + full_path)
			continue

func is_path_valid() -> bool:
	var valid := !resource_local_to_scene && !resource_path.is_empty()
	if !valid: push_error("MulticompileShader Error: Must be saved in a folder, cannot be a sub/local resource. " + resource_path)
	return valid
