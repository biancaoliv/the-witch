class_name Player extends CharacterBody2D

# Direção e movimentação
var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO
var move_speed : float = 100.0

# Estado atual da animação
var state : String = "idle"

# Referências aos nós
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var sprite : Sprite2D = $Sprite2D


# Inicialização
func _ready() -> void:
	pass


# Atualiza entrada do jogador e animações
func _process(delta: float) -> void:

	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")

	velocity = direction * move_speed

	if SetState() == true || SetDirection() == true:
		UpdateAnimation()


# Move o personagem utilizando a física da Godot
func _physics_process(delta: float) -> void:
	move_and_slide()


# Atualiza a direção em que o personagem está olhando
func SetDirection() -> bool:
	var new_direction : Vector2 = cardinal_direction

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


# Atualiza o estado (idle ou walk)
func SetState() -> bool:
	var new_state : String = "idle" if direction == Vector2.ZERO else "walk"

	if new_state == state:
		return false

	state = new_state
	return true


# Reproduz a animação correspondente ao estado e direção
func UpdateAnimation() -> void:
	animation_player.play(state + "_" + AnimDirection())


# Retorna o sufixo da animação baseado na direção atual
func AnimDirection() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	else:
		return "side"