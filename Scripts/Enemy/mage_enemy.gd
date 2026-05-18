# mage_enemy.gd
class_name MageEnemy
extends CharacterBase

func _on_ready_extra() -> void:
	max_health      = 100.0
	attack_damage   = 20.0
	move_speed      = 5.0
	walk_speed      = 2.5
	max_distance    = 20.0
	attack_distance = 2.0
	attack_cooldown = 0.5
	current_health  = max_health
