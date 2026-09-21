extends PanelContainer

@export_range(120, 240) var panel_width: int = 168
@export var background_color: Color = Color("#ffd18a")
@export var border_color: Color = Color("#875025")
@export var text_color: Color = Color("#432913")

var content: VBoxContainer


# Pode ser chamado antes de adicionar a cena à árvore.
func setup(data: ItemData) -> void:
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.x = panel_width
	var background := StyleBoxFlat.new()
	background.bg_color = background_color
	background.border_color = border_color
	background.set_border_width_all(2)
	background.content_margin_left = 8
	background.content_margin_right = 8
	background.content_margin_top = 6
	background.content_margin_bottom = 6
	add_theme_stylebox_override("panel", background)
	content = VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 4)
	add_child(content)
	if data == null:
		return
	_add_text(data.item_name if not data.item_name.is_empty() else "Item", 16, text_color)
	if not data.category.strip_edges().is_empty():
		_add_text(data.category, 11, Color("#97501f"))
	var has_description: bool = not data.description.strip_edges().is_empty()
	var has_effects: bool = data.energy != 0 or data.health != 0
	if has_description or has_effects:
		_add_separator()
	if has_description:
		_add_text(data.description, 12, text_color)
	if data.energy != 0:
		_add_text("%+d Energia" % data.energy, 12, _effect_color(data.energy))
	if data.health != 0:
		_add_text("%+d Saúde" % data.health, 12, _effect_color(data.health))
	if data.sell_price >= 0:
		_add_separator()
		_add_text("Venda: %d moedas / unidade" % data.sell_price, 11, text_color)


func _effect_color(amount: int) -> Color:
	return Color("#31551c") if amount > 0 else Color("#a12622")


func _add_text(value: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = value
	label.custom_minimum_size.x = panel_width - 16
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	content.add_child(label)


func _add_separator() -> void:
	var separator := HSeparator.new()
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := StyleBoxLine.new()
	line.color = Color("#bf8845")
	line.thickness = 1
	separator.add_theme_stylebox_override("separator", line)
	content.add_child(separator)
