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

	# Impede que esta interação também acione outros sistemas.
	get_viewport().set_input_as_handled()

	if event.is_action_pressed("space") and not event.is_echo():
		_sell_one()


func _sell_one() -> void:
	var slot: InventorySlot = player.inventory.get_selected_slot()

	if slot == null or slot.is_empty():
		print("Selecione uma colheita na Hotbar.")
		return

	if not slot.item.data is CropItemData:
		print("Este ponto vende apenas colheitas.")
		return

	var price: int = slot.item.data.sell_price

	if price <= 0:
		print("Esta colheita não possui um preço de venda válido.")
		return

	if player.wallet == null:
		return

	var item_name: String = slot.item.get_name()

	slot.remove(1)
	player.wallet.add_money(price)

	print("Vendido: ", item_name, " por ", price, " moedas.")