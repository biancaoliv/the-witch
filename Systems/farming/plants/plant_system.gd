class_name PlantSystem extends Node2D
const WORLD_ITEM_SCENE: PackedScene = preload(
	"res://Systems/world_items/world_item.tscn"
)


@export var plant_scene: PackedScene


@onready var farm_grid: FarmGrid = $"../FarmGrid"
@onready var farm_soil: TileMapLayer = $"../FarmSoil"
@onready var player: Player = $"../Player"
@onready var soil_system: SoilSystem = $"../SoilSystem"



func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("space"):
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

	return soil.can_plant()


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

	if not seed_data.plant_data.can_grow_in(GameClock.season):
		print("Esta semente não pode ser plantada nesta estação.")
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

func _ready() -> void:
	GameClock.season_changed.connect(_on_season_changed)


func _on_season_changed(new_season: int, _year: int) -> void:
	for cell in soil_system.soil_cells:
		var soil: SoilCell = soil_system.soil_cells[cell]
		var plant: Plant = soil.plant

		if not is_instance_valid(plant):
			continue

		if plant.is_queued_for_deletion() or plant.is_dead:
			continue

		if plant.plant_data == null:
			continue

		if plant.plant_data.can_grow_in(new_season):
			continue

		plant.die()
		soil_system.update_soil_visual(cell)

		print(
			plant.plant_data.plant_name,
			" morreu na mudança de estação."
		)

func _on_plant_harvested(plant: Plant, cell: Vector2i) -> void:
	var soil := soil_system.get_soil(cell)

	if soil == null or soil.plant != plant:
		return

	if plant.is_dead or not plant.ready_to_harvest:
		return

	var data: PlantData = plant.plant_data

	if data == null:
		return

	if data.harvest_item == null or data.harvest_quantity <= 0:
		push_warning("A planta está sem uma colheita válida.")
		return

	var drop := WORLD_ITEM_SCENE.instantiate() as WorldItem

	if drop == null:
		return

	# Configura antes de adicionar à árvore, pois _ready inicia o salto.
	drop.item_data = data.harvest_item
	drop.quantity = data.harvest_quantity

	var world := get_parent() as Node2D
	drop.position = world.to_local(plant.global_position)
	world.add_child(drop)

	# Libera a célula sem adicionar itens diretamente ao inventário.
	plant.ready_to_harvest = false
	plant.set_process_unhandled_input(false)

	soil.state = SoilCell.SoilState.TILLED
	soil.plant = null

	soil_system.update_soil_visual(cell)
	plant.queue_free()

func restore_plant(cell: Vector2i, data: Dictionary) -> bool:
	var soil: SoilCell = soil_system.get_soil(cell)
	if soil == null or plant_scene == null:
		return false

	if is_instance_valid(soil.plant):
		push_error("Já existe uma planta nesta célula.")
		return false

	var plant_id: Variant = data.get("plant_id")
	if not plant_id is String:
		return false

	var saved_plant_data: PlantData = PlantCatalog.get_plant(plant_id)
	if saved_plant_data == null:
		return false

	var instance := plant_scene.instantiate()
	var restored := instance as Plant

	if restored == null:
		instance.free()
		return false

	restored.plant_data = saved_plant_data
	restored.position = to_local(
		farm_soil.to_global(farm_soil.map_to_local(cell))
	)

	add_child(restored)

	# Valida e restaura antes de associar ao solo.
	if not restored.load_save_data(data):
		restored.free()
		push_error("Dados inválidos da planta: " + plant_id)
		return false

	restored.soil = soil
	soil.plant = restored

	if restored.is_dead:
		soil.state = SoilCell.SoilState.DEAD
		soil.set_watered(false)
	else:
		soil.state = SoilCell.SoilState.PLANTED

	restored.harvested.connect(
		_on_plant_harvested.bind(cell)
	)

	soil_system.update_soil_visual(cell)
	return true

