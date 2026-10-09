extends Node

const SAVE_PATH: String = "user://save_game.json"
const TEMP_PATH: String = "user://save_game.tmp"
const SAVE_VERSION: int = 1
const WORLD_ITEM_SCENE: PackedScene = preload("res://Systems/world_items/world_item.tscn")

var _load_failed: bool = false
var _starting: bool = true
var _previous_clock_pause: bool = false


func _ready() -> void:
	GameClock.morning_started.connect(
		_on_morning_started,
		CONNECT_DEFERRED
	)
	print("SaveManager pronto.")
	_previous_clock_pause = GameClock.paused
	GameClock.paused = true
	call_deferred("_load_on_start")


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func write_save(data: Dictionary) -> bool:
	if _load_failed or _starting:
		push_error("Salvamento bloqueado: carregamento pendente ou com falha.")
		return false
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
			"money": player.wallet.balance,
			"inventory": inventory_data
		},
		"clock": GameClock.get_save_data(),
		"soil": soil_data,
		"world_items": ground_items
	}

	return write_save(data)

func _on_morning_started() -> void:
	if _starting or _load_failed:
		return
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

	if not _wake_player(scene, player):
		return
	if save_game(player, soil):
		print("Salvamento automático da manhã concluído.")
	else:
		push_error("Falha no salvamento automático da manhã.")

func _load_on_start() -> void:
	if has_save():
		var data: Dictionary = read_save()
		if data.is_empty() or not _restore_game(data):
			_load_failed = true
			push_error("Não foi possível carregar. O arquivo salvo será preservado.")
		else:
			print("Partida carregada automaticamente.")
	else:
		var scene := get_tree().current_scene
		var player := scene.get_node_or_null("Player") as Player if scene != null else null
		if scene == null or player == null or not _wake_player(scene, player):
			_load_failed = true
			push_error("Configure WakePoint na fazenda antes de jogar.")
		else:
			print("Nenhum salvamento encontrado. Nova partida.")
	_starting = false
	GameClock.paused = _previous_clock_pause


func _restore_game(data: Dictionary) -> bool:
	var scene := get_tree().current_scene
	if not scene is Node2D:
		return false
	if data.get("scene_path") != scene.scene_file_path:
		push_error("Execute a cena da fazenda correspondente ao salvamento.")
		return false
	for key in ["player", "clock", "soil"]:
		if not data.get(key) is Dictionary:
			return false
	if not data.get("world_items") is Array:
		return false

	var player := scene.get_node_or_null("Player") as Player
	var soil := scene.get_node_or_null("SoilSystem") as SoilSystem
	if player == null or soil == null or not scene.get_node_or_null("WakePoint") is Marker2D:
		return false
	if not player.is_node_ready() or not soil.is_node_ready():
		return false
	if player.inventory == null or player.wallet == null:
		return false

	# Prepara todos os itens antes de alterar a partida.
	var prepared: Array[WorldItem] = []
	for entry in data["world_items"]:
		if not entry is Dictionary:
			_discard_items(prepared)
			return false
		var drop := WORLD_ITEM_SCENE.instantiate() as WorldItem
		if drop == null:
			_discard_items(prepared)
			return false
		if not drop.prepare_from_save(entry, scene):
			drop.free()
			_discard_items(prepared)
			return false
		prepared.append(drop)

	var previous_position: Vector2 = player.global_position
	var previous_clock: Dictionary = GameClock.get_save_data()
	var previous_player: Dictionary = {
		"money": player.wallet.balance,
		"inventory": player.inventory.get_save_data()
	}
	if previous_player["inventory"].is_empty():
		_discard_items(prepared)
		return false

	if not GameClock.load_save_data(data["clock"]):
		_discard_items(prepared)
		return false
	if not player.load_save_data(data["player"]):
		GameClock.load_save_data(previous_clock)
		_discard_items(prepared)
		return false
	if not soil.load_save_data(data["soil"]):
		player.load_save_data(previous_player)
		player.global_position = previous_position
		GameClock.load_save_data(previous_clock)
		_discard_items(prepared)
		return false

	# Remove os itens da cena inicial antes de adicionar os salvos.
	for node in get_tree().get_nodes_in_group("world_items"):
		if node is WorldItem and scene.is_ancestor_of(node):
			node.free()
	for drop in prepared:
		scene.add_child(drop)
	_wake_player(scene, player)
	return true


func _discard_items(items: Array[WorldItem]) -> void:
	for item in items:
		if is_instance_valid(item):
			item.free()


func _wake_player(scene: Node, player: Player) -> bool:
	var point := scene.get_node_or_null("WakePoint") as Marker2D
	if point == null:
		push_error("Adicione um Marker2D chamado WakePoint na raiz da fazenda.")
		return false
	player.global_position = point.global_position
	player.direction = Vector2.ZERO
	player.velocity = Vector2.ZERO
	player.change_state("idle")
	return true
