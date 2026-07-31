class_name PlayerState extends Node

# Armazena uma referência para o jogador, permitindo que outros scripts acessem o jogador
static var player: Player

func _ready() -> void:
	pass # Replace with function body.

# O que acontece quando o jogador entra nesse estado?
func enter() -> void:
	pass

# O que acontece quando o jogador sai desse estado?
func exit() -> void:
	pass

# O que acontece durante o _process(atualização) de processo neste estado?
func update(_delta: float) -> void:
	pass

# O que acontece durante o _physics_process(atualização física) de processo neste estado?
func physics_update(_delta: float) -> void:
	pass

# O que acontece com os eventos de entrada neste Estado?
func handle_input(_event: InputEvent) -> void:
	pass