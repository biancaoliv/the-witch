extends Label

@export var player: Player


func _ready() -> void:
	if player == null:
		text = "Moedas: --"
		return

	if not player.is_node_ready():
		await player.ready

	var wallet: Wallet = player.wallet

	if wallet == null:
		text = "Moedas: --"
		return

	wallet.balance_changed.connect(_update_balance)
	_update_balance(wallet.balance)


func _update_balance(new_balance: int) -> void:
	text = "Moedas: %d" % new_balance