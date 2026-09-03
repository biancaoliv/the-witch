class_name SeedStation extends Area2D


@export var seed_item_data: SeedItemData
@export var seed_amount: int = 1


var player_nearby: bool = false
var player: Player = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_released("space"):
		return

	if not player_nearby:
		return

	if player == null:
		return

	if seed_item_data == null:
		print("SeedItemData não definido na estação.")
		return

	var added := player.inventory.add_item_data(
		seed_item_data,
		seed_amount
	)

	if added:
		print(
			"Recebeu ",
			seed_amount,
			"x ",
			seed_item_data.item_name
		)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body
		player_nearby = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_nearby = false
		player = null