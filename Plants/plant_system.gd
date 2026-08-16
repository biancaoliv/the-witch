class_name PlantSystem extends Node2D


@export var plant_scene: PackedScene
var selected_plant_data: PlantData = null

var planted_cells: Dictionary = {}


@onready var farm_grid: FarmGrid = $"../FarmGrid"
@onready var farm_soil: TileMapLayer = $"../FarmSoil"


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("space"):
		var cell := farm_grid.get_target_cell()

		if can_plant(cell):
			plant(cell)


func has_soil(cell: Vector2i) -> bool:
	return farm_soil.get_cell_source_id(cell) != -1


func can_plant(cell: Vector2i) -> bool:
	if not has_soil(cell):
		return false

	if cell in planted_cells:
		return false

	return true


func plant(cell: Vector2i) -> void:
	if not can_plant(cell):
		return

	if selected_plant_data == null:
		print("Nenhuma semente selecionada!")
		return

	var new_plant := plant_scene.instantiate() as Plant

	new_plant.plant_data = selected_plant_data
	new_plant.position = farm_soil.map_to_local(cell)

	add_child(new_plant)

	planted_cells[cell] = new_plant

	print(
		"Plantado: ",
		selected_plant_data.plant_name,
		" na célula: ",
		cell
	)