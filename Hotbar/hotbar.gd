class_name Hotbar
extends Control


@export var player: Player


@onready var slots_ui: Array[HotbarSlot] = [
	$HBoxContainer/Slot1,
	$HBoxContainer/Slot2,
	$HBoxContainer/Slot3,
	$HBoxContainer/Slot4,
	$HBoxContainer/Slot5
]


func _process(_delta: float) -> void:
	if player == null:
		return

	update_hotbar()


func update_hotbar() -> void:
	var inventory := player.inventory

	for i in range(slots_ui.size()):
		if i >= inventory.slots.size():
			continue

		slots_ui[i].update_slot(inventory.slots[i])

		slots_ui[i].set_selected(
			i == inventory.selected_slot_index
		)
