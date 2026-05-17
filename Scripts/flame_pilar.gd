# flame_pillar.gd
extends Node3D

@export var rise_speed: float = 16.0
@export var target_y: float = 0.0  # Se asigna al spawnear
@export var damage_amount: float = 25.0

var _player_manager: Node = null
var _damage_dealt: bool = false
var _rising: bool = true

func _ready() -> void:
	var area := $Area3D as Area3D
	area.body_entered.connect(_on_body_entered)
	_player_manager = get_tree().get_first_node_in_group("player_manager")

func _process(delta: float) -> void:
	if not _rising:
		return
	global_position.y += rise_speed * delta
	if global_position.y >= target_y:
		global_position.y = target_y
		_rising = false
		# Espera un momento visible y se elimina
		await get_tree().create_timer(0.6).timeout
		queue_free()

func _on_body_entered(body: Node) -> void:
	if _damage_dealt or not body.is_in_group("player"):
		return
	_damage_dealt = true
	if _player_manager:
		_player_manager.take_damage(damage_amount)
