class_name Hotbar
extends Control

const WORLD_ITEM_SCENE: PackedScene = preload("res://Systems/world_items/world_item.tscn")
const CURSOR_SCENE: PackedScene = preload("res://Systems/inventory/inventory_slot_ui.tscn")

@export var player: Player
@export var drop_distance: float = 32.0

@onready var bar: HBoxContainer = $HBoxContainer

var slots_ui: Array[Control] = []
var cursor_slot: Control
var drag_index: int = -1
var drag_start: Vector2 = Vector2.ZERO
var dragging: bool = false
var snapshot: InventorySlot = InventorySlot.new()


func _ready() -> void:
	for child in bar.get_children():
		if child is Control:
			slots_ui.append(child)
	cursor_slot = CURSOR_SCENE.instantiate()
	add_child(cursor_slot)
	cursor_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_slot.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	cursor_slot.z_index = 100
	cursor_slot.hide()


func _process(_delta: float) -> void:
	if not is_instance_valid(player) or player.inventory == null:
		_cancel_drag()
		return
	if drag_index >= 0:
		if player.inventory.ui_open or not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_cancel_drag()
		elif not _source_unchanged():
			_cancel_drag()
		else:
			if drag_start.distance_to(get_local_mouse_position()) >= 4.0:
				dragging = true
			cursor_slot.visible = dragging
			cursor_slot.position = get_local_mouse_position() + Vector2(-4, -4)
			cursor_slot.call("update_slot", snapshot)
	update_hotbar()


func update_hotbar() -> void:
	var inventory: Inventory = player.inventory
	for i in range(slots_ui.size()):
		if i >= inventory.slots.size():
			continue
		if dragging and i == drag_index:
			slots_ui[i].call("update_slot", null)
		else:
			slots_ui[i].call("update_slot", inventory.slots[i])
		slots_ui[i].call("set_selected", i == inventory.selected_slot_index)


func _input(event: InputEvent) -> void:
	if not is_instance_valid(player) or player.inventory == null:
		return
	if player.inventory.ui_open:
		_cancel_drag()
		return
	# Abrir a mochila cancela o arraste da barra, sem retirar o item.
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_I:
			_cancel_drag()
			return
	if drag_index >= 0 and event.is_action("space"):
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		var index: int = _slot_under_mouse()
		if index < 0 or index >= player.inventory.slots.size():
			return
		get_viewport().set_input_as_handled()
		player.inventory.select_slot(index)
		var slot: InventorySlot = player.inventory.slots[index]
		if slot.is_empty():
			return
		drag_index = index
		drag_start = get_local_mouse_position()
		snapshot.item = slot.item
		snapshot.quantity = slot.quantity
		dragging = false
	elif drag_index >= 0:
		get_viewport().set_input_as_handled()
		if drag_start.distance_to(get_local_mouse_position()) >= 4.0:
			dragging = true
		if dragging and _source_unchanged():
			_finish_drag()
		_cancel_drag()
		update_hotbar()


func _slot_under_mouse() -> int:
	for i in range(slots_ui.size()):
		var slot_ui: Control = slots_ui[i]
		if slot_ui.is_visible_in_tree():
			if Rect2(Vector2.ZERO, slot_ui.size).has_point(slot_ui.get_local_mouse_position()):
				return i
	return -1


func _source_unchanged() -> bool:
	if drag_index < 0 or drag_index >= player.inventory.slots.size():
		return false
	var source: InventorySlot = player.inventory.slots[drag_index]
	return source.item == snapshot.item and source.quantity == snapshot.quantity


func _finish_drag() -> void:
	var target: int = _slot_under_mouse()
	if target >= 0:
		if target != drag_index:
			player.inventory.move_or_stack(drag_index, target)
		return
	# Soltar nos pequenos espaços entre slots apenas cancela.
	if Rect2(Vector2.ZERO, bar.size).has_point(bar.get_local_mouse_position()):
		return
	_drop_source()


func _drop_source() -> void:
	if not _source_unchanged():
		return
	var world := player.get_parent() as Node2D
	if world == null:
		return
	var drop = WORLD_ITEM_SCENE.instantiate()
	var source: InventorySlot = player.inventory.slots[drag_index]
	drop.item_data = source.item.data
	drop.quantity = source.quantity
	var direction: Vector2 = player.cardinal_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	drop.position = world.to_local(player.global_position + direction * drop_distance)
	source.remove(source.quantity)
	world.add_child(drop)


func _cancel_drag() -> void:
	drag_index = -1
	dragging = false
	snapshot.item = null
	snapshot.quantity = 0
	if is_instance_valid(cursor_slot):
		cursor_slot.hide()
