extends CanvasLayer

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthRow/ProgressBar
@onready var stamina_bar: ProgressBar = $MarginContainer/VBoxContainer/StaminaRow/ProgressBar

var player_manager: Node = null

func _ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	_find_player_manager()

func _find_player_manager() -> void:
	var managers = get_tree().get_nodes_in_group("player_manager")
	if managers.size() > 0:
		player_manager = managers[0]
		player_manager.health_changed.connect(_on_health_changed)
		player_manager.stamina_changed.connect(_on_stamina_changed)
		player_manager.player_died.connect(_on_player_died)
		health_bar.max_value = player_manager.max_health
		health_bar.value = player_manager.current_health
		stamina_bar.max_value = player_manager.max_stamina
		stamina_bar.value = player_manager.current_stamina
	else:
		push_warning("PlayerHUD: No node found in group 'player_manager'")

func _on_health_changed(current: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current

func _on_stamina_changed(current: float, max_stamina: float) -> void:
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current

func _on_player_died() -> void:
	visible = false
