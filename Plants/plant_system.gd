class_name PlantSystem extends Node2D


@export var plant_scene: PackedScene


var planted_cells: Dictionary[Vector2i, Plant] = {}


@onready var farm_grid: FarmGrid = $"../FarmGrid"
@onready var farm_soil: TileMapLayer = $"../FarmSoil"
@onready var player: Player = $"../Player"
@onready var soil_system: SoilSystem = $"../SoilSystem"


func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed("space"):
		return

	var slot := player.inventory.get_selected_slot()

	if slot == null:
		return

	if slot.is_empty():
		return

	if not slot.item.data is SeedItemData:
		return

	var cell := farm_grid.get_target_cell()

	if can_plant(cell):
		plant(cell, slot)


func can_plant(cell: Vector2i) -> bool:
	var soil := soil_system.get_soil(cell)

	if soil == null:
		return false

	if not soil.can_plant():
		return false

	if cell in planted_cells:
		return false

	return true


func plant(cell: Vector2i, slot: InventorySlot) -> void:
	if not can_plant(cell):
		return

	if slot == null or slot.is_empty():
		return

	var seed_data := slot.item.data as SeedItemData

	if seed_data == null:
		return

	if seed_data.plant_data == null:
		return

	var soil := soil_system.get_soil(cell)

	if soil == null:
		return

	var new_plant := plant_scene.instantiate() as Plant

	if new_plant == null:
		return

	new_plant.plant_data = seed_data.plant_data
	new_plant.soil = soil
	new_plant.position = farm_soil.map_to_local(cell)

	add_child(new_plant)

	new_plant.harvested.connect(
		_on_plant_harvested.bind(cell)
	)

	planted_cells[cell] = new_plant

	soil.state = SoilCell.SoilState.PLANTED
	soil.plant = new_plant

	soil_system.update_soil_visual(cell)

	# Consome uma semente do slot selecionado
	slot.remove(1)

	print(
		"Plantado: ",
		seed_data.plant_data.plant_name,
		" | sementes restantes: ",
		slot.quantity
	)


func _on_plant_harvested(plant: Plant, cell: Vector2i) -> void:
	var soil := soil_system.get_soil(cell)

	if soil == null:
		return

	var plant_data := plant.plant_data

	if plant_data.harvest_item != null:
		player.inventory.add_item_data(
			plant_data.harvest_item,
			plant_data.harvest_quantity
		)

	soil.state = SoilCell.SoilState.TILLED
	soil.plant = null

	soil_system.update_soil_visual(cell)

	planted_cells.erase(cell)

	plant.queue_free()

	print("Célula liberada após colheita: ", cell)
