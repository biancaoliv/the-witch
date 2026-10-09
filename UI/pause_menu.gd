extends CanvasLayer

var overlay: Control
var resume_button: Button
var confirmation: ConfirmationDialog
var status: Label
var pending_action: String = ""
var opened: bool = false
var previous_clock_pause: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.05, 0.04, 0.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 310
	column.add_theme_constant_override("separation", 10)
	center.add_child(column)
	var title := Label.new()
	title.text = "Jogo pausado"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	column.add_child(title)
	resume_button = _button("Continuar", column)
	resume_button.pressed.connect(resume_game)
	_button("Voltar ao menu inicial", column).pressed.connect(_request_exit.bind("menu"))
	_button("Sair do jogo", column).pressed.connect(_request_exit.bind("quit"))
	status = Label.new()
	status.text = "Esc para continuar • O jogo está pausado"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 13)
	column.add_child(status)

	confirmation = ConfirmationDialog.new()
	confirmation.title = "Sair da partida?"
	confirmation.dialog_text = "O progresso desde a última manhã salva será perdido.
Deseja continuar?"
	confirmation.cancel_button_text = "Cancelar"
	confirmation.confirmed.connect(_confirm_exit)
	confirmation.canceled.connect(_cancel_exit)
	add_child(confirmation)
	overlay.hide()


func _button(text: String, parent: Control) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 40
	parent.add_child(button)
	return button


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode != KEY_ESCAPE:
		return
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path != SaveManager.FARM_SCENE or SaveManager.busy:
		return
	get_viewport().set_input_as_handled()
	if confirmation.visible:
		confirmation.hide()
		_cancel_exit()
	elif opened:
		resume_game()
	else:
		pause_game()


func pause_game() -> void:
	if opened or SaveManager.busy:
		return
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path != SaveManager.FARM_SCENE:
		return
	# Interrompe apenas o gesto do mouse; o item segurado continua no inventário.
	var inventory_ui := scene.get_node_or_null("CanvasLayer/InventoryUi")
	if inventory_ui != null:
		inventory_ui.tracking_left_drag = false
		inventory_ui.picked_on_press = false
	var hotbar := scene.get_node_or_null("CanvasLayer/UI Control/Hotbar(control)")
	if hotbar != null:
		hotbar._cancel_drag()
	previous_clock_pause = GameClock.paused
	GameClock.paused = true
	get_tree().paused = true
	opened = true
	overlay.show()
	resume_button.grab_focus()


func resume_game() -> void:
	if not opened:
		return
	confirmation.hide()
	pending_action = ""
	overlay.hide()
	opened = false
	get_tree().paused = false
	GameClock.paused = previous_clock_pause


func _request_exit(action: String) -> void:
	pending_action = action
	confirmation.ok_button_text = "Voltar ao menu" if action == "menu" else "Sair"
	confirmation.popup_centered(Vector2i(460, 150))


func _cancel_exit() -> void:
	pending_action = ""
	resume_button.grab_focus()


func _confirm_exit() -> void:
	var action: String = pending_action
	pending_action = ""
	if action == "quit":
		get_tree().quit()
	elif action == "menu":
		SaveManager.menu_error = ""
		GameClock.paused = true
		var result: Error = get_tree().change_scene_to_file(SaveManager.MENU_SCENE)
		if result != OK:
			status.text = "Não foi possível abrir o menu."
			return
		await get_tree().scene_changed
		confirmation.hide()
		overlay.hide()
		opened = false
		get_tree().paused = false
