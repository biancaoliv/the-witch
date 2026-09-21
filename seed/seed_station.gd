class_name SeedStation
extends Area2D

@export var seed_item_data: SeedItemData
@export_range(1, 999) var seed_amount: int = 1
@export_range(1, 999999) var unit_price: int = 2

var player: Player = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(player):
		return

	if player.inventory.ui_open:
		return

	if not event.is_action("space"):
		return

	get_viewport().set_input_as_handled()

	if event.is_action_pressed("space") and not event.is_echo():
		_buy_seeds()


func _buy_seeds() -> void:
	if seed_item_data == null or seed_amount <= 0 or unit_price <= 0:
		return

	var inventory: Inventory = player.inventory
	var wallet: Wallet = player.wallet

	if inventory == null or wallet == null:
		return

	var total_price: int = seed_amount * unit_price

	if wallet.balance < total_price:
		print("Moedas insuficientes. Preço: ", total_price)
		return

	if not inventory.can_add_item_data(seed_item_data, seed_amount):
		print("Não há espaço para todas as sementes.")
		return

	# O espaço e o saldo já foram verificados.
	if inventory.add_item_data(seed_item_data, seed_amount):
		wallet.spend_money(total_price)
		print(
			"Comprou ", seed_amount,
			"x ", seed_item_data.item_name,
			" por ", total_price, " moedas."
		)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body


func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player = null