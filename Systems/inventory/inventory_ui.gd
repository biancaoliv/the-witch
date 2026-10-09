extends Control

const SLOT_SCENE: PackedScene = preload("res://Systems/inventory/inventory_slot_ui.tscn")

const WORLD_ITEM_SCENE: PackedScene = preload(
	"res://Systems/world_items/world_item.tscn"
)

var drag_start_position: Vector2 = Vector2.ZERO
var tracking_left_drag: bool = false
var picked_on_press: bool = false

@export var player: Player
@onready var grid: GridContainer = $Panel/MarginContainer/GridContainer

var held: InventorySlot = InventorySlot.new()
var origin_index: int = -1
var cursor_slot: Control


func _ready() -> void:
	hide()
	cursor_slot = SLOT_SCENE.instantiate()
	add_child(cursor_slot)
	cursor_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_slot.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	cursor_slot.z_index = 100
	cursor_slot.hide()


func _process(_delta: float) -> void:
	_refresh()
	if is_instance_valid(cursor_slot):
		cursor_slot.position = get_local_mouse_position() + Vector2(-4, -4)


func _get_inventory() -> Inventory:
	if not is_instance_valid(player):
		return null
	return player.inventory

func _refresh() -> void:
	var inventory: Inventory = _get_inventory()
	if inventory == null:
		return
	if grid.get_child_count() != inventory.slots.size():
		for child in grid.get_children():
			grid.remove_child(child)
			child.queue_free()
		for i in range(inventory.slots.size()):
			var slot_ui = SLOT_SCENE.instantiate()
			grid.add_child(slot_ui)
			slot_ui.clicked.connect(_on_slot_clicked.bind(i))
			slot_ui.right_clicked.connect(_on_slot_right_clicked.bind(i))
	for i in range(inventory.slots.size()):
		grid.get_child(i).update_slot(inventory.slots[i])
		grid.get_child(i).set_selected(not held.is_empty() and i == origin_index)
	if is_instance_valid(cursor_slot):
		cursor_slot.call("update_slot", held)
		cursor_slot.visible = visible and not held.is_empty()
		cursor_slot.position = get_local_mouse_position() + Vector2(-4, -4)
	if held.is_empty():
		origin_index = -1

# Transfers only what fits. The remaining quantity stays in the source.
func _transfer(source: InventorySlot, destination: InventorySlot, requested: int) -> void:
	if source == destination or source.is_empty() or requested <= 0:
		return
	if not destination.is_empty() and destination.item.data != source.item.data:
		return
	var available: int = maxi(0, source.item.get_max_stack() - destination.quantity)
	var amount: int = mini(requested, mini(source.quantity, available))
	if amount <= 0:
		return
	destination.item = source.item
	destination.quantity += amount
	source.remove(amount)

func _on_slot_clicked(index: int) -> void:
	var inventory: Inventory = _get_inventory()
	if not visible or inventory == null:
		return
	if index < 0 or index >= inventory.slots.size():
		return
	var slot: InventorySlot = inventory.slots[index]
	if held.is_empty():
		if slot.is_empty():
			return
		origin_index = index
		_transfer(slot, held, slot.quantity)
	elif slot.is_empty() or slot.item.data == held.item.data:
		_transfer(held, slot, held.quantity)
	else:
		var saved_item: Item = slot.item
		var saved_quantity: int = slot.quantity
		slot.item = held.item
		slot.quantity = held.quantity
		held.item = saved_item
		held.quantity = saved_quantity
		origin_index = index
	_refresh()

func _on_slot_right_clicked(index: int) -> void:
	var inventory: Inventory = _get_inventory()
	if not visible or inventory == null:
		return
	if index < 0 or index >= inventory.slots.size():
		return
	var slot: InventorySlot = inventory.slots[index]
	if held.is_empty():
		if slot.is_empty():
			return
		var amount: int = 1
		if Input.is_key_pressed(KEY_SHIFT):
			amount = maxi(1, floori(slot.quantity / 2.0))
		origin_index = index
		_transfer(slot, held, amount)
	else:
		# With an item in hand, right click places one unit.
		_transfer(held, slot, 1)
	_refresh()

func _return_held(inventory: Inventory) -> bool:
	if held.is_empty():
		return true
	if origin_index >= 0 and origin_index < inventory.slots.size():
		_transfer(held, inventory.slots[origin_index], held.quantity)
	for slot in inventory.slots:
		if held.is_empty():
			return true
		if not slot.is_empty():
			_transfer(held, slot, held.quantity)
	for slot in inventory.slots:
		if held.is_empty():
			return true
		if slot.is_empty():
			_transfer(held, slot, held.quantity)
	return held.is_empty()


func _slot_at_position(viewport_position: Vector2) -> int:
	for i in range(grid.get_child_count()):
		var slot_ui := grid.get_child(i) as Control
		var local_position: Vector2 = slot_ui.get_global_transform_with_canvas().affine_inverse() * viewport_position
		if Rect2(Vector2.ZERO, slot_ui.size).has_point(local_position):
			return i
	return -1


func _outside_panel(viewport_position: Vector2) -> bool:
	var panel: Control = $Panel
	var local_position: Vector2 = panel.get_global_transform_with_canvas().affine_inverse() * viewport_position
	return not Rect2(Vector2.ZERO, panel.size).has_point(local_position)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_I:
			tracking_left_drag = false
			picked_on_press = false
			_set_inventory_open(not visible)
			get_viewport().set_input_as_handled()
			return

	if not visible:
		return
	if event.is_action("space"):
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventMouseButton:
		return

	var index: int = _slot_at_position(event.position)
	if event.button_index == MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		if event.pressed and index >= 0:
			tracking_left_drag = false
			picked_on_press = false
			_on_slot_right_clicked(index)
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	# Um único caminho trata o clique; impede processamento duplicado na GUI.
	get_viewport().set_input_as_handled()
	if event.pressed:
		drag_start_position = event.position
		tracking_left_drag = true
		picked_on_press = held.is_empty() and index >= 0
		if index >= 0:
			_on_slot_clicked(index)
		picked_on_press = picked_on_press and not held.is_empty()
		return

	if not tracking_left_drag:
		return
	tracking_left_drag = false
	var was_pickup: bool = picked_on_press
	picked_on_press = false
	if held.is_empty():
		return

	if _outside_panel(event.position):
		_drop_held_item()
		return

	# Só deposita na soltura quando este gesto começou pegando uma pilha.
	# Uma troca feita ao pressionar não deve ser desfeita ao soltar.
	if was_pickup and drag_start_position.distance_to(event.position) >= 4.0:
		if index >= 0:
			_on_slot_clicked(index)

func _set_inventory_open(open: bool) -> void:
	tracking_left_drag = false
	picked_on_press = false
	var inventory: Inventory = _get_inventory()
	if inventory == null:
		return
	if not open and not _return_held(inventory):
		print("Coloque o item segurado em um slot antes de fechar o inventário.")
		_refresh()
		return
	inventory.ui_open = open
	visible = open
	if open:
		player.direction = Vector2.ZERO
		player.velocity = Vector2.ZERO
		player.change_state("idle")
	_refresh()

func _drop_held_item() -> void:
	if held.is_empty() or not is_instance_valid(player):
		return

	var world := player.get_parent() as Node2D

	if world == null:
		return

	var drop := WORLD_ITEM_SCENE.instantiate() as WorldItem

	if drop == null:
		return

	drop.item_data = held.item.data
	drop.quantity = held.quantity

	var direction: Vector2 = player.cardinal_direction.normalized()

	if direction == Vector2.ZERO:
		direction = Vector2.DOWN

	var drop_position: Vector2 = (
		player.global_position + direction * 32.0
	)

	drop.position = world.to_local(drop_position)
	world.add_child(drop)

	held.item = null
	held.quantity = 0
	origin_index = -1

	_refresh()

func prepare_for_save() -> bool:
	var inventory: Inventory = _get_inventory()
	if inventory == null:
		return false

	# Devolve o item do cursor ao inventário.
	# Se não couber, coloca o restante no chão.
	if not _return_held(inventory):
		_drop_held_item()

	if not held.is_empty():
		push_error("Não foi possível guardar o item do cursor.")
		return false

	_set_inventory_open(false)
	return not inventory.ui_open
