class_name WorldItem
extends Node2D

@export var item_data: ItemData
@export_range(1, 9999) var quantity: int = 1

@export var jump_height: float = 20.0
@export var jump_duration: float = 0.45

var can_pickup: bool = false
var restored_from_save: bool = false

@onready var visual: Node2D = $Visual
@onready var icon: Sprite2D = $Visual/Icon
@onready var pickup_area: Area2D = $PickupArea



func _ready() -> void:
	add_to_group("world_items")

	if item_data == null:
		push_warning("WorldItem está sem ItemData.")
		return

	icon.texture = item_data.icon

	if restored_from_save:
		visual.position = Vector2.ZERO
		can_pickup = true
	else:
		_play_drop_animation()


func _play_drop_animation() -> void:
	can_pickup = false
	visual.position = Vector2.ZERO

	var duration: float = maxf(jump_duration, 0.1)
	var height: float = maxf(jump_height, 0.0)
	var tween := create_tween()

	# Sobe desacelerando.
	tween.tween_property(
		visual,
		"position:y",
		-height,
		duration * 0.5
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Cai acelerando.
	tween.tween_property(
		visual,
		"position:y",
		0.0,
		duration * 0.5
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.tween_callback(_on_landed)


func _on_landed() -> void:
	can_pickup = true

func _physics_process(_delta: float) -> void:
	if not can_pickup or is_queued_for_deletion():
		return

	if item_data == null or quantity <= 0:
		return

	for body in pickup_area.get_overlapping_bodies():
		if not body is Player:
			continue

		var player := body as Player

		if player.inventory == null:
			continue

		var collected: int = player.inventory.collect_item_data(
			item_data,
			quantity
		)

		quantity -= collected

		if quantity <= 0:
			can_pickup = false
			queue_free()
			return

func get_save_data() -> Dictionary:
	if item_data == null or item_data.item_id.is_empty():
		push_error("Item no chão sem Item Id.")
		return {}

	if quantity <= 0 or is_queued_for_deletion():
		return {}

	if ItemCatalog.get_item(item_data.item_id) != item_data:
		push_error("Item no chão não corresponde ao catálogo.")
		return {}

	return {
		"item_id": item_data.item_id,
		"quantity": quantity,
		"position": {
			"x": global_position.x,
			"y": global_position.y
		}
	}

func prepare_from_save(data: Dictionary, world: Node2D) -> bool:
	# Configura o item antes de adicioná-lo à cena.
	if is_inside_tree() or not is_instance_valid(world):
		return false

	var saved_id: Variant = data.get("item_id")
	var amount: Variant = data.get("quantity")
	var saved_position: Variant = data.get("position")

	if not saved_id is String:
		return false

	if not (amount is int or amount is float):
		return false
	if not is_finite(float(amount)):
		return false
	if float(amount) != floor(float(amount)):
		return false
	if amount < 1 or amount > 2147483647:
		return false

	if not saved_position is Dictionary:
		return false

	for axis in ["x", "y"]:
		var value: Variant = saved_position.get(axis)
		if not (value is int or value is float):
			return false
		if not is_finite(float(value)):
			return false

	var restored_data: ItemData = ItemCatalog.get_item(saved_id)
	if restored_data == null:
		return false

	item_data = restored_data
	quantity = int(amount)
	position = world.to_local(Vector2(
		float(saved_position["x"]),
		float(saved_position["y"])
	))
	restored_from_save = true
	return true