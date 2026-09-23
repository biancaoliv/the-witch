extends Area2D

var player: Player = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body


func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player = null


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(player):
		return

	if player.inventory.ui_open:
		return

	if not event.is_action("space"):
		return

	get_viewport().set_input_as_handled()

	if event.is_action_pressed("space") and not event.is_echo():
		_sleep()


func _sleep() -> void:
	player.direction = Vector2.ZERO
	player.velocity = Vector2.ZERO
	player.change_state("idle")

	GameClock.advance_to_next_morning()

	print(
		"Acordou às ",
		GameClock.get_time_text(),
		" — ",
		GameClock.get_date_text()
	)