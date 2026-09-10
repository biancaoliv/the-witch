class_name FarmGrid extends Node2D


@onready var farm_soil: TileMapLayer = $"../FarmSoil"
@onready var player: Player = $"../Player"
@onready var grid_cursor: Sprite2D = $"../GridCursor"


func _process(_delta: float) -> void:
	var cell := get_target_cell()
	update_cursor(cell)


func get_target_cell() -> Vector2i:
	var local_position := farm_soil.to_local(player.global_position)
	var cell := farm_soil.local_to_map(local_position)
	var direction := Vector2i(player.cardinal_direction)

	return cell + direction


func has_soil(cell: Vector2i) -> bool:
	return farm_soil.get_cell_source_id(cell) != -1


func update_cursor(cell: Vector2i) -> void:
	if not has_soil(cell):
		grid_cursor.visible = false
		return

	grid_cursor.visible = true
	grid_cursor.position = farm_soil.map_to_local(cell)