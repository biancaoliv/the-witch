class_name Inventory
extends Node


@export var inventory_size: int = 20
@export var starting_hoe: ToolItemData
@export var starting_watering_can: ToolItemData


var slots: Array[InventorySlot] = []
var selected_slot_index: int = 0


func _ready() -> void:
	initialize_inventory()

	if starting_hoe != null:
		add_item_data(starting_hoe, 1)

	if starting_watering_can != null:
		add_item_data(starting_watering_can, 1)


func initialize_inventory() -> void:
	slots.clear()

	for i in range(inventory_size):
		slots.append(InventorySlot.new())

	print("Inventário criado com ", slots.size(), " slots.")


func add_item_data(item_data: ItemData, quantity: int = 1) -> bool:
	if item_data == null:
		return false

	var new_item := Item.new(item_data)

	return add_item(new_item, quantity)


func add_item(new_item: Item, quantity: int = 1) -> bool:
	if new_item == null:
		return false

	var remaining: int = quantity

	# Primeiro tenta completar stacks existentes
	for slot in slots:
		if slot.can_stack(new_item) and not slot.is_empty():
			remaining = slot.add(remaining)

			if remaining <= 0:
				print(
				new_item.get_name(),
				" agora possui x",
				slot.quantity
)

				return true

	# Depois procura slots vazios
	for slot in slots:
		if slot.is_empty():
			slot.item = new_item
			remaining = slot.add(remaining)

			if remaining <= 0:
				print(
					"Item adicionado: ",
					new_item.get_name(),
					" x",
					quantity
				)

				return true

	print("Inventário cheio!")

	return false

func get_selected_slot() -> InventorySlot:
	if selected_slot_index < 0:
		return null

	if selected_slot_index >= slots.size():
		return null

	return slots[selected_slot_index]

func get_selected_item() -> Item:
	var slot := get_selected_slot()

	if slot == null:
		return null

	if slot.is_empty():
		return null

	return slot.item

func select_slot(index: int) -> void:
	if index < 0 or index >= slots.size():
		return

	selected_slot_index = index

	var slot := get_selected_slot()

	if slot == null or slot.is_empty():
		print("Slot ", index + 1, " selecionado: vazio")
		return

	print(
		"Slot ",
		index + 1,
		" selecionado: ",
		slot.item.get_name(),
		" x",
		slot.quantity
	)

func select_next_slot() -> void:
	var next_index: int = selected_slot_index + 1

	if next_index > 4:
		next_index = 0

	select_slot(next_index)


func select_previous_slot() -> void:
	var previous_index: int = selected_slot_index - 1

	if previous_index < 0:
		previous_index = 4

	select_slot(previous_index)
	
func _input(event: InputEvent) -> void:
	# Rodinha do mouse
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			select_previous_slot()

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			select_next_slot()

	# Teclas
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			select_slot(0)

		elif event.keycode == KEY_2:
			select_slot(1)

		elif event.keycode == KEY_3:
			select_slot(2)

		elif event.keycode == KEY_4:
			select_slot(3)

		elif event.keycode == KEY_5:
			select_slot(4)