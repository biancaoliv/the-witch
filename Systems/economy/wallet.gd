class_name Wallet
extends Node

signal balance_changed(new_balance: int)

@export_range(0, 999999) var starting_money: int = 0

var balance: int = 0


func _ready() -> void:
	balance = maxi(0, starting_money)
	balance_changed.emit(balance)


func add_money(amount: int) -> void:
	if amount <= 0:
		return

	balance += amount
	balance_changed.emit(balance)


func spend_money(amount: int) -> bool:
	if amount <= 0 or amount > balance:
		return false

	balance -= amount
	balance_changed.emit(balance)
	return true