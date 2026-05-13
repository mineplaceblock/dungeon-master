extends StaticBody3D

## Damage dealt per hit (or per second if continuous)
@export var damage_amount: float = 10.0
## If true, deals damage every interval while touching. If false, deals damage once on enter.
@export var continuous_damage: bool = false
## Seconds between damage ticks (only used when continuous_damage is true)
@export var damage_interval: float = 0.5

## Path to the PlayerManager node (adjust to your scene tree)
@export var player_manager_path: NodePath = NodePath("../Player/PlayerManager")

var _player_manager: Node = null
var _player_inside: bool = false
var _tick_timer: float = 0.0

func _ready() -> void:
	# Connect body_entered / body_exited from an Area3D child named "HurtArea"
	# Add an Area3D child node to this StaticBody3D and name it "HurtArea"
	var area := $HurtArea as Area3D
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	_player_manager = get_node(player_manager_path)

func _process(delta: float) -> void:
	if not continuous_damage or not _player_inside:
		return
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = damage_interval
		_deal_damage()

func _on_body_entered(body: Node) -> void:
	if not body is CharacterBody3D:
		return
	_player_inside = true
	_tick_timer = 0.0  # deal damage immediately on enter
	if not continuous_damage:
		_deal_damage()

func _on_body_exited(body: Node) -> void:
	if not body is CharacterBody3D:
		return
	_player_inside = false

func _deal_damage() -> void:
	if _player_manager:
		_player_manager.take_damage(damage_amount)
