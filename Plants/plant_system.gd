class_name PlantSystem extends Node2D


@export var plant_scene: PackedScene

var selected_plant_data: PlantData = null
var planted_cells: Dictionary[Vector2i, Plant] = {}


@onready var farm_grid: FarmGrid = $"../FarmGrid"
@onready var farm_soil: TileMapLayer = $"../FarmSoil"
@onready var player: Player = $"../Player"
@onready var soil_system: SoilSystem = $"../SoilSystem"


func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed("space"):
		return

	if player.equipped_tool != Player.EquippedTool.SEED:
		return

	var cell := farm_grid.get_target_cell()

	if can_plant(cell):
		plant(cell)


func can_plant(cell: Vector2i) -> bool:
	var soil := soil_system.get_soil(cell)

	if soil == null:
		return false

	if not soil.can_plant():
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

	# Pega o solo correspondente à célula
	var soil := soil_system.get_soil(cell)

	if soil == null:
		return

	# Cria a planta
	var new_plant := plant_scene.instantiate() as Plant

	if new_plant == null:
		return

	# Passa os dados para a planta ANTES de adicioná-la à cena
	new_plant.plant_data = selected_plant_data
	new_plant.soil = soil
	new_plant.position = farm_soil.map_to_local(cell)

	add_child(new_plant)

	# Escuta quando essa planta for colhida
	new_plant.harvested.connect(
		_on_plant_harvested.bind(cell)
	)

	# Registra a planta
	planted_cells[cell] = new_plant

	# Atualiza o conceito do solo
	soil.state = SoilCell.SoilState.PLANTED
	soil.plant = new_plant

	soil_system.update_soil_visual(cell)

	print(
		"Plantado: ",
		selected_plant_data.plant_name,
		" na célula: ",
		cell
	)


func _on_plant_harvested(plant: Plant, cell: Vector2i) -> void:
	var soil := soil_system.get_soil(cell)

	if soil == null:
		return

	# O solo volta a ficar apenas arado
	soil.state = SoilCell.SoilState.TILLED

	# Remove a referência da planta
	soil.plant = null

	# Atualiza visualmente o solo
	soil_system.update_soil_visual(cell)

	# Libera a célula
	planted_cells.erase(cell)

	# Remove a planta
	plant.queue_free()

	print("Célula liberada após colheita: ", cell)