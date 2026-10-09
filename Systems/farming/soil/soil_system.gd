class_name SoilSystem extends Node2D


@onready var farm_grid: FarmGrid = $"../FarmGrid"
@onready var farm_soil: TileMapLayer = $"../FarmSoil"
@onready var player: Player = $"../Player"


var soil_cells: Dictionary[Vector2i, SoilCell] = {}
var last_processed_morning: int = -1


const NORMAL_SOURCE_ID := 0
const NORMAL_ATLAS := Vector2i(6, 13)

const TILLED_SOURCE_ID := 1
const TILLED_ATLAS := Vector2i(2, 0)

const WATERED_SOURCE_ID := 1
const WATERED_ATLAS := Vector2i(0, 2)


func _ready() -> void:
	initialize_soil_cells()
	GameClock.morning_started.connect(_on_morning_started)


func initialize_soil_cells() -> void:
	var used_cells := farm_soil.get_used_cells()

	for cell in used_cells:
		var soil := SoilCell.new()

		var source_id := farm_soil.get_cell_source_id(cell)
		var atlas_coords := farm_soil.get_cell_atlas_coords(cell)

		if source_id == NORMAL_SOURCE_ID and atlas_coords == NORMAL_ATLAS:
			soil.state = SoilCell.SoilState.VIRGIN

		elif source_id == TILLED_SOURCE_ID and atlas_coords == TILLED_ATLAS:
			soil.state = SoilCell.SoilState.TILLED

		elif source_id == WATERED_SOURCE_ID and atlas_coords == WATERED_ATLAS:
			soil.state = SoilCell.SoilState.TILLED
			soil.set_watered(true)

		soil_cells[cell] = soil

	print("Solos registrados: ", soil_cells.size())


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("space"):
		return

	var slot := player.inventory.get_selected_slot()

	if slot == null or slot.is_empty():
		return

	if not slot.item.data is ToolItemData:
		return

	var tool_data := slot.item.data as ToolItemData
	var cell := farm_grid.get_target_cell()

	if tool_data.tool_type == ToolItemData.ToolType.HOE:
		till_soil(cell)

	elif tool_data.tool_type == ToolItemData.ToolType.WATERING_CAN:
		water_soil(cell)


func get_soil(cell: Vector2i) -> SoilCell:
	if not cell in soil_cells:
		return null

	return soil_cells[cell]


func has_soil(cell: Vector2i) -> bool:
	return cell in soil_cells


func till_soil(cell: Vector2i) -> void:
	var soil := get_soil(cell)

	if soil == null:
		return

	# A enxada limpa os restos da planta morta.
	if soil.state == SoilCell.SoilState.DEAD:
		if is_instance_valid(soil.plant):
			soil.plant.queue_free()

		soil.plant = null
		soil.state = SoilCell.SoilState.TILLED
		soil.set_watered(false)

		update_soil_visual(cell)
		print("Planta morta removida.")
		return

	if not soil.can_till():
		return

	soil.state = SoilCell.SoilState.TILLED
	soil.set_watered(false)

	update_soil_visual(cell)
	print("Solo arado em: ", cell)


func water_soil(cell: Vector2i) -> void:
	var soil := get_soil(cell)

	if soil == null:
		return

	if not soil.can_water():
		return

	soil.set_watered(true)

	update_soil_visual(cell)

	print("Solo molhado em: ", cell)


func update_soil_visual(cell: Vector2i) -> void:
	var soil := get_soil(cell)

	if soil == null:
		return

	if soil.state == SoilCell.SoilState.DEAD:
		set_tilled_visual(cell)
		return

	if soil.state == SoilCell.SoilState.VIRGIN:
		set_normal_visual(cell)
		return

	if soil.state == SoilCell.SoilState.TILLED:
		if soil.watered:
			set_watered_visual(cell)
		else:
			set_tilled_visual(cell)
		return

	if soil.state == SoilCell.SoilState.PLANTED:
		if soil.watered:
			set_watered_visual(cell)
		else:
			set_tilled_visual(cell)


func set_normal_visual(cell: Vector2i) -> void:
	farm_soil.set_cell(
		cell,
		NORMAL_SOURCE_ID,
		NORMAL_ATLAS
	)


func set_tilled_visual(cell: Vector2i) -> void:
	farm_soil.set_cell(
		cell,
		TILLED_SOURCE_ID,
		TILLED_ATLAS
	)


func set_watered_visual(cell: Vector2i) -> void:
	farm_soil.set_cell(
		cell,
		WATERED_SOURCE_ID,
		WATERED_ATLAS
	)

func _on_morning_started() -> void:
	if last_processed_morning == GameClock.total_days:
		return

	last_processed_morning = GameClock.total_days

	for cell in soil_cells:
		var soil: SoilCell = soil_cells[cell]

		# A planta verifica a água antes de o solo secar.
		if is_instance_valid(soil.plant):
			if not soil.plant.is_queued_for_deletion():
				soil.plant.grow_one_day()

		soil.set_watered(false)
		update_soil_visual(cell)

func get_save_data() -> Dictionary:
	var saved_cells: Array = []

	for cell in soil_cells:
		var soil: SoilCell = soil_cells[cell]
		var plant_save: Dictionary = {}

		if is_instance_valid(soil.plant):
			if soil.plant.is_queued_for_deletion():
				push_error("Aguarde a remoção da planta antes de salvar.")
				return {}

			plant_save = soil.plant.get_save_data()
			if plant_save.is_empty():
				return {}

		saved_cells.append({
			"x": cell.x,
			"y": cell.y,
			"state": int(soil.state),
			"watered": soil.watered,
			"fertilized": soil.fertilized,
			"plant": plant_save
		})

	return {
		"cells": saved_cells,
		"last_processed_morning": last_processed_morning
	}
# Adicione estas funções ao final de soil_system.gd.
func load_save_data(data: Dictionary) -> bool:
	var plant_system := get_node_or_null("../PlantSystem") as PlantSystem
	if plant_system == null:
		return false
	var entries: Variant = data.get("cells")
	var morning: Variant = data.get("last_processed_morning")
	if not entries is Array or not _save_integer(morning):
		return false
	if morning < -1 or morning > GameClock.total_days:
		return false
	if entries.size() != soil_cells.size():
		push_error("O solo salvo não corresponde ao mapa atual.")
		return false

	var prepared: Dictionary[Vector2i, SoilCell] = {}
	var plants: Dictionary = {}
	for entry in entries:
		if not entry is Dictionary:
			return false
		for key in ["x", "y", "state"]:
			if not _save_integer(entry.get(key)):
				return false
		if abs(float(entry["x"])) > 2147483647 or abs(float(entry["y"])) > 2147483647:
			return false
		var cell := Vector2i(int(entry["x"]), int(entry["y"]))
		if not soil_cells.has(cell) or prepared.has(cell):
			return false
		if entry["state"] < 0 or entry["state"] >= SoilCell.SoilState.size():
			return false
		if not entry.get("watered") is bool or not entry.get("fertilized") is bool:
			return false
		var plant_data: Variant = entry.get("plant")
		if not plant_data is Dictionary:
			return false
		var state: int = int(entry["state"])
		var needs_plant: bool = state == SoilCell.SoilState.PLANTED or state == SoilCell.SoilState.DEAD
		if needs_plant == plant_data.is_empty():
			return false
		if needs_plant:
			if not plant_data.get("is_dead") is bool:
				return false
			if plant_data["is_dead"] != (state == SoilCell.SoilState.DEAD):
				return false
		if state == SoilCell.SoilState.DEAD and entry["watered"]:
			return false
		var soil := SoilCell.new()
		soil.state = state
		soil.watered = entry["watered"]
		soil.fertilized = entry["fertilized"]
		prepared[cell] = soil
		plants[cell] = plant_data

	# Mantém o solo anterior disponível caso uma planta não possa ser restaurada.
	var previous: Dictionary[Vector2i, SoilCell] = soil_cells
	soil_cells = prepared
	for cell in plants:
		if plants[cell].is_empty():
			continue
		if not plant_system.restore_plant(cell, plants[cell]):
			for new_soil in prepared.values():
				if is_instance_valid(new_soil.plant):
					new_soil.plant.free()
			soil_cells = previous
			for old_cell in soil_cells:
				update_soil_visual(old_cell)
			push_error("Não foi possível restaurar a plantação. Solo anterior mantido.")
			return false

	for old_soil in previous.values():
		if is_instance_valid(old_soil.plant):
			old_soil.plant.free()
	last_processed_morning = int(morning)
	for cell in soil_cells:
		update_soil_visual(cell)
	return true


func _save_integer(value: Variant) -> bool:
	if not (value is int or value is float):
		return false
	return is_finite(float(value)) and float(value) == floor(float(value))
