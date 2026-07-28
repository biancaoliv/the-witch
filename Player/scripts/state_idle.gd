class_name State_Idle extends State

@onready var walk : State = $"../walk"

# O que acontece quando o jogador entra nesse estado?
func Enter() -> void:
	player.UpdateAnimation("idle")
	pass

# O que acontece quando o jogador sai desse estado?
func Exit() -> void:
	pass

# O que acontece durante o _process(atualização) de processo neste estado?
func Process( _delta : float) -> State:
	if player.direction != Vector2.ZERO:
		return walk
	player.velocity = Vector2.ZERO
	return null

# O que acontece durante o _physics_process(atualização física) de processo neste estado?
func Physics(_delta : float) -> State:
	return null

# O que acontece com os eventos de entrada neste Estado?
func HandleInput( _event: InputEvent) -> State:
	return null