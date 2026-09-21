extends PanelContainer

const TOOLTIP_SCENE: PackedScene = preload("res://Systems/inventory/item_tooltip.tscn")
var displayed_data: ItemData = null

signal clicked
signal right_clicked

var selected: bool = false

@onready var icon: TextureRect = $MarginContainer/Icon
@onready var quantity_label: Label = $MarginContainer/Quantity


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	$MarginContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tooltip_theme := Theme.new()
	tooltip_theme.set_stylebox("panel", "TooltipPanel", StyleBoxEmpty.new())
	theme = tooltip_theme
	update_slot(null)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			clicked.emit()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			accept_event()
			right_clicked.emit()


func set_selected(value: bool) -> void:
	if selected == value:
		return

	selected = value
	queue_redraw()


func _draw() -> void:
	if selected:
		var border := Rect2(Vector2.ONE, size - Vector2(2, 2))
		draw_rect(border, Color("#ffd36a"), false, 2.0)


func update_slot(slot: InventorySlot) -> void:
	displayed_data = null if slot == null or slot.is_empty() else slot.item.data
	if slot == null or slot.is_empty():
		icon.texture = null
		quantity_label.text = ""
		tooltip_text = ""
		return

	icon.texture = slot.item.get_icon()
	tooltip_text = slot.item.get_name() if not slot.item.get_name().is_empty() else "Item"

	if slot.quantity > 1:
		quantity_label.text = str(slot.quantity)
	else:
		quantity_label.text = ""

func _make_custom_tooltip(for_text: String) -> Object:
	if displayed_data == null or for_text.is_empty():
		return null
	var panel = TOOLTIP_SCENE.instantiate()
	panel.setup(displayed_data)
	return panel

