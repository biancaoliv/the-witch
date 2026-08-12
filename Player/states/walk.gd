extends PlayerState

@export var move_speed: float = 100.0

# O que acontece quando o jogador entra nesse estado?
func enter() -> void:
	player.update_animation("walk")


func physics_update(_delta: float) -> void:
	if not player.is_moving():
		player.change_state("idle")
		return

	player.velocity = player.direction * move_speed

	if player.set_direction():
		player.update_animation("walk")