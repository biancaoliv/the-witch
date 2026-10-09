extends Control

var continue_button: Button
var new_button: Button
var status: Label
var confirmation: ConfirmationDialog


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameClock.paused = true
	var background := ColorRect.new()
	background.color = Color("#172722")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(300, 0)
	column.add_theme_constant_override("separation", 12)
	center.add_child(column)

	var title := Label.new()
	title.text = "THE WITCH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Um novo dia na fazenda"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle)

	continue_button = _make_button("Continuar", column)
	continue_button.disabled = not SaveManager.has_save()
	continue_button.pressed.connect(_continue_game)
	new_button = _make_button("Novo jogo", column)
	new_button.pressed.connect(_request_new_game)

	status = Label.new()
	status.custom_minimum_size = Vector2(300, 40)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 14)
	status.text = SaveManager.menu_error
	if status.text.is_empty():
		status.text = "O progresso é salvo ao dormir." if SaveManager.has_save() else "Nenhuma partida salva."
	column.add_child(status)

	confirmation = ConfirmationDialog.new()
	confirmation.title = "Começar um novo jogo?"
	confirmation.dialog_text = "Sua partida salva será substituída.
Deseja começar novamente no dia 1?"
	confirmation.ok_button_text = "Começar novo jogo"
	confirmation.cancel_button_text = "Cancelar"
	confirmation.confirmed.connect(_new_game)
	add_child(confirmation)
	if continue_button.disabled:
		new_button.grab_focus()
	else:
		continue_button.grab_focus()


func _make_button(text: String, parent: Control) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 42
	parent.add_child(button)
	return button


func _request_new_game() -> void:
	if SaveManager.has_save():
		confirmation.popup_centered(Vector2i(390, 150))
	else:
		_new_game()


func _new_game() -> void:
	_start(true)


func _continue_game() -> void:
	_start(false)


func _start(new_game: bool) -> void:
	if SaveManager.busy:
		return
	continue_button.disabled = true
	new_button.disabled = true
	status.text = "Preparando a fazenda…"
	var manager: Node = SaveManager
	# A operação continua no Autoload quando o menu sai da árvore.
	manager.start_game(new_game)
	if is_inside_tree() and not SaveManager.busy:
		status.text = SaveManager.menu_error
		continue_button.disabled = not SaveManager.has_save()
		new_button.disabled = false
