class_name Item extends RefCounted


var data: ItemData


func _init(item_data: ItemData) -> void:
	data = item_data


func get_name() -> String:
	return data.item_name


func get_icon() -> Texture2D:
	return data.icon


func get_max_stack() -> int:
	return data.max_stack