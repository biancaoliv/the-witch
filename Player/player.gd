class_name Player extends CharacterBody2D

# Direção e movimentação
var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO

# FMS
var states: Dictionary[String, PlayerState]
var prev_state: PlayerState
var current_state: PlayerState

# Referências aos nós
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D


# Inicialização
func _ready():
	_initialize_states()


# Atualiza entrada do jogador e animações
func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

	
# Move o personagem utilizando a física da Godot
func _physics_process(delta: float) -> void:
	direction = Input.get_vector("left", "right", "up", "down")

	if current_state:
		current_state.physics_update(delta)

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


func _initialize_states():
	var initial_state: PlayerState = null

	for c in $States.get_children():
		if c is PlayerState:
			c.player = self
			states.set(c.name.to_lower(), c)

			if initial_state == null:
				initial_state = c

	if initial_state:
		change_state(initial_state.name)


func change_state(state_name: String) -> void:
	var new_state = states.get(state_name.to_lower())

	if new_state == null:
		return

	if current_state:
		current_state.exit()
		prev_state = current_state

	current_state = new_state
	current_state.enter()


func is_moving() -> bool:
	return direction != Vector2.ZERO


# Atualiza a direção em que o personagem está olhando
func set_direction() -> bool:
	var new_direction: Vector2 = cardinal_direction

	if direction == Vector2.ZERO:
		return false

	if direction.y == 0:
		new_direction = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT
	elif direction.x == 0:
		new_direction = Vector2.UP if direction.y < 0 else Vector2.DOWN

	if new_direction == cardinal_direction:
		return false

	cardinal_direction = new_direction

	# Inverter o eixo x do sprite para que ele vire de acordo com a direção
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1

	return true


# Reproduz a animação correspondente ao estado e direção
func update_animation(state: String) -> void:
	animation_player.play(state + "_" + anim_direction())


# Retorna o sufixo da animação baseado na direção atual
func anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	else:
		return "side"
