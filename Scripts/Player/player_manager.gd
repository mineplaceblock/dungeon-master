extends Node

signal health_changed(current: float, max_health: float)
signal stamina_changed(current: float, max_stamina: float)
signal player_died

@export var max_health: float = 100.0
@export var max_stamina: float = 100.0

## Stamina drain per second while sprinting
@export var stamina_drain_rate: float = 20.0
## Stamina regen per second while not sprinting
@export var stamina_regen_rate: float = 10.0
## Seconds to wait before stamina starts regenerating after sprinting
@export var stamina_regen_delay: float = 1.5

var current_health: float = 100.0
var current_stamina: float = 100.0
var _stamina_regen_timer: float = 0.0
var _is_dead: bool = false

func _ready() -> void:
	add_to_group("player_manager")
	current_health = max_health
	current_stamina = max_stamina

func _process(delta: float) -> void:
	_handle_stamina_regen(delta)

# ─── PUBLIC API ───────────────────────────────────────────────

## Deal damage to the player. Returns true if the player died.
func take_damage(amount: float) -> bool:
	if _is_dead:
		return true
	current_health = max(current_health - amount, 0.0)
	emit_signal("health_changed", current_health, max_health)
	if current_health <= 0.0:
		_die()
		return true
	return false

## Heal the player (capped at max_health).
func heal(amount: float) -> void:
	if _is_dead:
		return
	current_health = min(current_health + amount, max_health)
	emit_signal("health_changed", current_health, max_health)

## Try to consume stamina (e.g. while sprinting). Returns false if not enough stamina.
func consume_stamina(amount: float) -> bool:
	if max(current_stamina - amount, 0.0) <= 0.0:
		return false
	current_stamina = max(current_stamina - amount, 0.0)
	_stamina_regen_timer = stamina_regen_delay  # reset regen delay
	emit_signal("stamina_changed", current_stamina, max_stamina)
	return true

func has_stamina() -> bool:
	return current_stamina > 0.0

# ─── INTERNAL ─────────────────────────────────────────────────

func _handle_stamina_regen(delta: float) -> void:
	if _stamina_regen_timer > 0.0:
		_stamina_regen_timer -= delta
		return
	if current_stamina < max_stamina:
		current_stamina = min(current_stamina + stamina_regen_rate * delta, max_stamina)
		emit_signal("stamina_changed", current_stamina, max_stamina)

func _die() -> void:
	_is_dead = true
	emit_signal("player_died")
	print("Player died.")
