class_name State extends Node

# Armazena uma referência para o jogador, permitindo que outros scripts acessem o jogador
static var player: Player

func _ready() -> void:
	pass # Replace with function body.

# O que acontece quando o jogador entra nesse estado?
func Enter() -> void:
	pass

# O que acontece quando o jogador sai desse estado?
func Exit() -> void:
	pass

# O que acontece durante o _process(atualização) de processo neste estado?
func Process( _delta : float) -> State:
	return null

# O que acontece durante o _physics_process(atualização física) de processo neste estado?
func Physics(_delta : float) -> State:
	return null

# O que acontece com os eventos de entrada neste Estado?
func HandleInput( _event: InputEvent) -> State:
	return null