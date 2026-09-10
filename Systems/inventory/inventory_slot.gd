class_name InventorySlot extends RefCounted


var item: Item = null
var quantity: int = 0


func is_empty() -> bool:
	return item == null or quantity <= 0


func can_stack(new_item: Item) -> bool:
	if is_empty():
		return true

	return (
		item.data == new_item.data
		and quantity < item.get_max_stack()
	)


func add(amount: int = 1) -> int:
	if item == null:
		return amount

	var available_space: int = item.get_max_stack() - quantity
	var amount_to_add: int = mini(amount, available_space)

	quantity += amount_to_add

	return amount - amount_to_add


func remove(amount: int = 1) -> int:
	var amount_to_remove: int = mini(amount, quantity)

	quantity -= amount_to_remove

	if quantity <= 0:
		item = null
		quantity = 0

	return amount_to_remove