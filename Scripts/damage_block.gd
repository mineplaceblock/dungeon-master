extends StaticBody3D

## Damage dealt per hit (or per second if continuous)
@export var damage_amount: float = 10.0
## If true, deals damage every interval while touching. If false, deals damage once on enter.
@export var continuous_damage: bool = false
## Seconds between damage ticks (only used when continuous_damage is true)
@export var damage_interval: float = 0.5


var _player_manager: Node = null
var _player_inside: bool = false
var _tick_timer: float = 0.0

func _ready() -> void:
	var area := $HurtArea as Area3D
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	_player_manager = get_tree().get_first_node_in_group("player_manager")
	print("PlayerManager encontrado: ", _player_manager)
	print("Area3D encontrada: ", area)


func _process(delta: float) -> void:
	if not continuous_damage or not _player_inside:
		return
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = damage_interval
		_deal_damage()
		print("Pupa")

func _on_body_entered(body: Node) -> void:
	print("Body entered: ", body.name, " | in group player: ", body.is_in_group("player"))
	if not body.is_in_group("player"):
		return
	_player_inside = true
	_tick_timer = 0.0
	print("Player detectado, continuous: ", continuous_damage)
	if not continuous_damage:
		_deal_damage()

func _deal_damage() -> void:
	print("Intentando daño, manager: ", _player_manager)
	if _player_manager:
		print("Vida antes: ", _player_manager.current_health)
		_player_manager.take_damage(damage_amount)
		print("Vida después: ", _player_manager.current_health)

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = false
