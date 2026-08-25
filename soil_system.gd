class_name SoilSystem extends Node2D


@onready var farm_grid: FarmGrid = $"../FarmGrid"
@onready var farm_soil: TileMapLayer = $"../FarmSoil"
@onready var player: Player = $"../Player"


var soil_cells: Dictionary[Vector2i, SoilCell] = {}


const NORMAL_SOURCE_ID := 0
const NORMAL_ATLAS := Vector2i(6, 13)

const TILLED_SOURCE_ID := 1
const TILLED_ATLAS := Vector2i(2, 0)

const WATERED_SOURCE_ID := 1
const WATERED_ATLAS := Vector2i(0, 2)


func _ready() -> void:
	initialize_soil_cells()


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


func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed("space"):
		return

	var cell := farm_grid.get_target_cell()

	if player.equipped_tool == Player.EquippedTool.HOE:
		till_soil(cell)

	elif player.equipped_tool == Player.EquippedTool.WATERING_CAN:
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