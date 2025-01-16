@tool
class_name MulticompileMaterial
extends ShaderMaterial

@export var source: MulticompileShader: set = set_source
@export_storage var defines: PackedStringArray

func set_source(v: MulticompileShader) -> void:
	source = v
	if source: source.get_shader(defines)
	notify_property_list_changed()

func _get_property_list() -> Array[Dictionary]:
	if !source: return []
	return source.proplist

func _get(property: StringName) -> Variant:
	if !source: return null
	if !source.proplist_dict.has(property): return null
	
	var prop := source.proplist_dict[property] as Dictionary
	
	if prop.type == TYPE_BOOL:
		return defines.has(property)
	else:
		for enum_string in (prop.hint_string as String).split(","):
			var at := defines.find(property + "_" + enum_string)
			if at != -1:
				return enum_string
		return ""

func _set(property: StringName, value: Variant) -> bool:
	if !source: return false
	if !source.proplist_dict.has(property): return false
	
	var prop := source.proplist_dict[property] as Dictionary
	
	if prop.type == TYPE_BOOL:
		var at := defines.find(property)
		if value == true:
			if at == -1: defines.append(property)
		else:
			if at != -1: defines.remove_at(at)
	else:
		for enum_string in (prop.hint_string as String).split(","):
			var at := defines.find(property + "_" + enum_string)
			if at != -1: defines.remove_at(at)
		if !(value as String).is_empty():
			defines.append(property + "_" + (value as String))
	
	shader = source.get_shader(defines)
	return true

func _validate_property(property: Dictionary) -> void:
	if property.name == &"shader":
		property.usage = PROPERTY_USAGE_STORAGE

func _property_can_revert(property: StringName) -> bool:
	if !source: return false
	if !source.proplist_dict.has(property): return false
	
	var prop := source.proplist_dict[property] as Dictionary
	if prop.type == TYPE_BOOL:
		return defines.has(property)
	else:
		for enum_string in (prop.hint_string as String).split(","):
			var at := defines.find(property + "_" + enum_string)
			if at != -1:
				return true
	
	return false

func _property_get_revert(property: StringName) -> Variant:
	if !source: return null
	if !source.proplist_dict.has(property): return null
	
	var prop := source.proplist_dict[property] as Dictionary
	if prop.type == TYPE_BOOL:
		return false
	else:
		return ""
