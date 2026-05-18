extends Control

## HealthBar.gd
## Adjunta este script al nodo raíz Control (HealthBar).
## Estructura esperada:
##   HealthBar (Control)  <-- este script
##   └── Panel
##       ├── DamageBar  (ProgressBar)  <- barra roja del daño
##       └── HealthBar  (ProgressBar)  <- barra de vida actual

# ──────────────────────────────────────────────
# Exportables (editables desde el Inspector)
# ──────────────────────────────────────────────

## Vida máxima del personaje.
@export var max_health: float = 100.0

## Velocidad con la que la DamageBar se "drena" hacia la vida actual (unidades/segundo).
@export var damage_drain_speed: float = 20.0

## Tiempo de espera (segundos) antes de que la DamageBar empiece a drenarse.
@export var damage_delay: float = 0.8

# ──────────────────────────────────────────────
# Referencias internas
# ──────────────────────────────────────────────
@onready var _health_bar: ProgressBar = $Panel/HealthBar
@onready var _damage_bar: ProgressBar = $Panel/DamageBar

var _current_health: float
var _drain_timer: float = 0.0   # tiempo restante antes de drenar
var _draining: bool = false

# ──────────────────────────────────────────────
# Señales
# ──────────────────────────────────────────────
signal health_changed(new_health: float, max_health: float)
signal health_depleted()

# ──────────────────────────────────────────────
# Inicialización
# ──────────────────────────────────────────────
func _ready() -> void:
	_setup_bars()
	set_health(max_health)

func _setup_bars() -> void:
	for bar in [_health_bar, _damage_bar]:
		bar.min_value = 0.0
		bar.max_value = max_health

# ──────────────────────────────────────────────
# Proceso
# ──────────────────────────────────────────────
func _process(delta: float) -> void:
	if not _draining:
		return

	if _drain_timer > 0.0:
		_drain_timer -= delta
		return

	# Drenar DamageBar hacia la vida actual
	if _damage_bar.value > _health_bar.value:
		_damage_bar.value = move_toward(
			_damage_bar.value,
			_health_bar.value,
			damage_drain_speed * delta
		)
	else:
		_draining = false

# ──────────────────────────────────────────────
# API pública
# ──────────────────────────────────────────────

## Establece la vida de golpe (sin animación de daño).
## Útil para inicializar o para cargar una partida guardada.
func set_health(value: float) -> void:
	_current_health = clampf(value, 0.0, max_health)
	_health_bar.value = _current_health
	_damage_bar.value = _current_health
	_draining = false
	health_changed.emit(_current_health, max_health)


## Aplica daño. La DamageBar muestra el cambio en rojo antes de drenarse.
func take_damage(amount: float) -> void:
	if amount <= 0.0:
		return

	_current_health = clampf(_current_health - amount, 0.0, max_health)
	_health_bar.value = _current_health   # barra verde baja de inmediato

	# La DamageBar se queda donde estaba y luego se drena con delay
	_drain_timer = damage_delay
	_draining = true

	health_changed.emit(_current_health, max_health)

	if _current_health <= 0.0:
		health_depleted.emit()


## Recupera vida. La DamageBar sube junto con la barra principal (no hay animación de curación roja).
func heal(amount: float) -> void:
	if amount <= 0.0:
		return

	_current_health = clampf(_current_health + amount, 0.0, max_health)
	_health_bar.value = _current_health
	# Si había daño pendiente de drenar y curamos por encima, lo ajustamos
	_damage_bar.value = maxf(_damage_bar.value, _current_health)

	health_changed.emit(_current_health, max_health)


## Cambia la vida máxima en tiempo de ejecución y reescala las barras.
func set_max_health(new_max: float, keep_ratio: bool = true) -> void:
	var ratio := _current_health / max_health if keep_ratio else 1.0
	max_health = maxf(new_max, 1.0)
	_setup_bars()
	set_health(max_health * ratio if keep_ratio else _current_health)


## Devuelve la vida actual.
func get_health() -> float:
	return _current_health


## Devuelve la vida actual como porcentaje (0.0 – 1.0).
func get_health_ratio() -> float:
	return _current_health / max_health


## Devuelve true si el personaje está vivo.
func is_alive() -> bool:
	return _current_health > 0.0
