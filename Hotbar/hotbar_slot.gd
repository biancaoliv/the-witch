class_name HotbarSlot
extends PanelContainer

@export var normal_background: Texture2D
@export var selected_background: Texture2D

@onready var background: TextureRect = $MarginContainer/Control/Background
@onready var icon: TextureRect = $MarginContainer/Control/Icon
@onready var quantity_label: Label = $MarginContainer/Control/Label


func update_slot(slot: InventorySlot) -> void:
	if slot == null or slot.is_empty():
		icon.texture = null
		quantity_label.text = ""
		return

	icon.texture = slot.item.get_icon()

	if slot.quantity > 1:
		quantity_label.text = str(slot.quantity)
	else:
		quantity_label.text = ""


func set_selected(selected: bool) -> void:
	if selected:
		background.texture = selected_background
	else:
		background.texture = normal_background
