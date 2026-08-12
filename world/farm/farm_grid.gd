class_name FarmGrid extends Node2D

@onready var farm_soil: TileMapLayer = $"../FarmSoil"
@onready var player: CharacterBody2D = $"../Player"
@onready var grid_cursor: Sprite2D = $"../GridCursor"

# Recursos de sementes pré-carregados
@onready var tomato_data: CropData = preload("res://Crops/Data/tomato.tres")
@onready var corn_data: CropData = preload("res://Crops/Data/corn.tres")
@onready var beet_data: CropData = preload("res://Crops/Data/beet.tres")

# Cena genérica da planta para ser instanciada dinamicamente
var crop_scene: PackedScene = preload("res://Crops/crop.tscn")

# Semente atualmente selecionada pelo jogador
var selected_seed: CropData

# Dicionário que mapeia a coordenada do grid para a instância da planta
var planted_crops: Dictionary[Vector2i, Crop] = {}


func _ready() -> void:
	# Começa com tomate selecionado por padrão
	selected_seed = null


func _process(_delta: float) -> void:
	var cell := get_player_cell()
	update_cursor(cell)

	# Seleção manual rápida de sementes via teclado
	_handle_seed_selection()

	# Planta ao pressionar "space" se a célula for fértil e estiver livre
	if Input.is_action_just_pressed("space"):
		if can_plant(cell) and not cell in planted_crops:
			plant_crop(cell)


func _handle_seed_selection() -> void:
	if Input.is_key_pressed(KEY_1):
		selected_seed = tomato_data
		print("Semente equipada: Tomate")
	elif Input.is_key_pressed(KEY_2):
		selected_seed = corn_data
		print("Semente equipada: Milho")
	elif Input.is_key_pressed(KEY_3):
		selected_seed = beet_data
		print("Semente equipada: Beterraba")


func get_player_cell() -> Vector2i:
	var local_position := farm_soil.to_local(player.global_position)
	var cell := farm_soil.local_to_map(local_position)
	var direction := Vector2i(player.cardinal_direction)

	return cell + direction


func can_plant(cell: Vector2i) -> bool:
	return farm_soil.get_cell_source_id(cell) != -1


func update_cursor(cell: Vector2i) -> void:
	if not can_plant(cell):
		grid_cursor.visible = false
		return

	grid_cursor.visible = true
	grid_cursor.position = farm_soil.map_to_local(cell)


# Cria dinamicamente a planta no grid
func plant_crop(cell: Vector2i) -> void:
	if selected_seed == null:
		print("Nenhuma semente selecionada!")
		return

	var new_crop := crop_scene.instantiate() as Crop
	new_crop.crop_data = selected_seed

	# Alinha a posição global da planta com o centro da célula
	new_crop.global_position = farm_soil.map_to_local(cell)

	# Adiciona a planta como filha do FarmGrid para organização
	add_child(new_crop)

	# Registra a planta no dicionário de controle
	planted_crops[cell] = new_crop

	# Inicia o ciclo de crescimento dela
	new_crop.plant()

	print("Plantado ", selected_seed.crop_name, " na célula ", cell)


# Função chamada pela planta ao ser colhida para liberar o espaço do Grid
func remove_crop_at_position(global_pos: Vector2) -> void:
	var local_pos := farm_soil.to_local(global_pos)
	var cell := farm_soil.local_to_map(local_pos)

	if cell in planted_crops:
		planted_crops.erase(cell)
		print("Célula liberada no grid: ", cell)