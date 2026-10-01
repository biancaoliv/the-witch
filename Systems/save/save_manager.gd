extends Node

const SAVE_PATH: String = "user://save_game.json"
const TEMP_PATH: String = "user://save_game.tmp"
const SAVE_VERSION: int = 1


func _ready() -> void:
	GameClock.morning_started.connect(
		_on_morning_started,
		CONNECT_DEFERRED
	)
	print("SaveManager pronto.")


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func write_save(data: Dictionary) -> bool:
	var document: Dictionary = {
		"version": SAVE_VERSION,
		"data": data
	}

	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Não foi possível criar o arquivo de salvamento.")
		return false

	file.store_string(JSON.stringify(document, "\t"))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()

	if write_error != OK:
		push_error("Erro ao gravar o salvamento.")
		return false

	var result: Error = DirAccess.rename_absolute(
		ProjectSettings.globalize_path(TEMP_PATH),
		ProjectSettings.globalize_path(SAVE_PATH)
	)

	if result != OK:
		push_error("Não foi possível finalizar o salvamento.")
		return false

	print("Jogo salvo.")
	return true


func read_save() -> Dictionary:
	if not has_save():
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Não foi possível abrir o salvamento.")
		return {}

	var content: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(content) != OK:
		push_error("Arquivo de salvamento inválido.")
		return {}

	var document: Variant = json.data
	if not document is Dictionary:
		push_error("Formato de salvamento inválido.")
		return {}

	if document.get("version", -1) != SAVE_VERSION:
		push_error("Versão de salvamento incompatível.")
		return {}

	var data: Variant = document.get("data")
	if not data is Dictionary:
		push_error("Dados de salvamento inválidos.")
		return {}

	return data

func save_player(player: Player) -> bool:
	if not is_instance_valid(player):
		push_error("Jogador inválido para salvar.")
		return false

	if player.inventory == null or player.wallet == null:
		push_error("Inventário ou carteira indisponível.")
		return false

	# Evita salvar enquanto um item está segurado pelo cursor.
	if player.inventory.ui_open or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		print("Feche o inventário e solte o mouse antes de salvar.")
		return false

	var inventory_data: Dictionary = player.inventory.get_save_data()
	if inventory_data.is_empty():
		return false

	var data: Dictionary = {
		"player": {
			"position": {
				"x": player.global_position.x,
				"y": player.global_position.y
			},
			"money": player.wallet.balance,
			"inventory": inventory_data
		}
	}

	return write_save(data)

func save_game(player: Player, soil_system: SoilSystem) -> bool:
	if not is_instance_valid(player) or not is_instance_valid(soil_system):
		push_error("Jogador ou sistema de solo indisponível.")
		return false

	if player.inventory == null or player.wallet == null:
		push_error("Inventário ou carteira indisponível.")
		return false

	if player.inventory.ui_open:
		push_warning("O inventário precisa estar fechado para salvar.")
		return false

	var inventory_data: Dictionary = player.inventory.get_save_data()
	var soil_data: Dictionary = soil_system.get_save_data()

	if inventory_data.is_empty() or soil_data.is_empty():
		return false

	var ground_items: Array = []

	for node in get_tree().get_nodes_in_group("world_items"):
		if not node is WorldItem:
			continue
		if node.is_queued_for_deletion():
			continue

		var item_save: Dictionary = node.get_save_data()
		if item_save.is_empty():
			return false

		ground_items.append(item_save)

	var data: Dictionary = {
		"scene_path": get_tree().current_scene.scene_file_path,
		"player": {
			"position": {
				"x": player.global_position.x,
				"y": player.global_position.y
			},
			"money": player.wallet.balance,
			"inventory": inventory_data
		},
		"clock": GameClock.get_save_data(),
		"soil": soil_data,
		"world_items": ground_items
	}

	return write_save(data)

func _on_morning_started() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var player := scene.get_node_or_null("Player") as Player
	var soil := scene.get_node_or_null("SoilSystem") as SoilSystem
	var inventory_ui := scene.get_node_or_null("CanvasLayer/InventoryUi")

	if player == null or soil == null or inventory_ui == null:
		push_error("Salvamento automático: nós da fazenda não encontrados.")
		return

	if not inventory_ui.has_method("prepare_for_save"):
		push_error("Inventário sem a função prepare_for_save.")
		return

	if not inventory_ui.call("prepare_for_save"):
		return

	if save_game(player, soil):
		print("Salvamento automático da manhã concluído.")
	else:
		push_error("Falha no salvamento automático da manhã.")