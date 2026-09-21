extends Control

const SLOT_SCENE: PackedScene = preload("res://Systems/inventory/inventory_slot_ui.tscn")

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
		cursor_slot.position = get_local_mouse_position() + Vector2(8, 8)
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


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_I:
			_set_inventory_open(not visible)
			get_viewport().set_input_as_handled()
			return
	if visible and event.is_action("space"):
		get_viewport().set_input_as_handled()

func _set_inventory_open(open: bool) -> void:
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