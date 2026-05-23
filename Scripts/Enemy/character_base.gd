# character_base.gd
class_name CharacterBase
extends CharacterBody3D

@export var max_health: float       = 100.0
@export var attack_damage: float    = 10.0
@export var move_speed: float       = 5.0
@export var walk_speed: float       = 2.5
@export var max_distance: float     = 20.0
@export var attack_distance: float  = 2.5
@export var attack_cooldown: float  = 0.5

@export var health_bar_visible_time: float = 3.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var attack_hitbox: Area3D        = $AttackHitbox
@onready var collision: CollisionShape3D  = $CollisionShape3D

@onready var _hb_pivot: Node3D    = get_node_or_null("HealthBarPivot")
@onready var _hb_ui: Control      = get_node_or_null("%HealthBar")
@onready var _hb_sprite: Sprite3D = get_node_or_null("HealthBarPivot/Sprite3D")

@export var anim_idle: String        = "Descansar"
@export var anim_run: String         = "Running_A"
@export var anim_walk: String        = "Walking_B"
@export var anim_attack: String      = "Atacar"
@export var anim_attack_back: String = "Atacar_2"
@export var anim_death: String       = "Death_A"

var current_health: float
var target: Node3D      = null
var spawn_position: Vector3
var active: bool        = true
var is_attacking: bool  = false
var attack_timer: float = 0.0

var _hb_visibility_timer: float = 0.0
var _hb_last_health: float      = 0.0

signal health_changed(new_health: float, max_health: float)
signal died

# ── Setup ─────────────────────────────────────────────────────
func setup_health(new_max: float) -> void:
	max_health     = new_max
	current_health = new_max
	if _hb_ui != null:
		_hb_ui.set_max_health(new_max)
		_hb_ui.set_health(new_max)
	health_changed.emit(current_health, max_health)

# Hook vacío que los hijos pueden sobreescribir sin tocar _ready
func _on_ready_extra() -> void:
	pass

func _ready() -> void:
	current_health    = max_health
	spawn_position    = global_position
	floor_snap_length = 0.5
	floor_max_angle   = deg_to_rad(60)

	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	_find_player()
	_setup_navigation()

	anim_player.animation_finished.connect(_on_animation_finished)
	anim_player.play(anim_idle)

	_setup_health_bar()
	health_changed.connect(_on_health_changed_hb)
	died.connect(_on_died_hb)

	_on_ready_extra()

func _setup_health_bar() -> void:
	if _hb_ui == null:
		return
	_hb_ui.set_max_health(max_health)
	_hb_ui.set_health(current_health)
	_hb_last_health = current_health
	_hb_ui.hide()

# ── HealthBar 3D ──────────────────────────────────────────────
func _process(delta: float) -> void:
	if _hb_ui == null:
		return
	_hb_update_visibility(delta)
	_hb_billboard()

func _hb_update_visibility(delta: float) -> void:
	if _hb_is_chasing():
		_hb_ui.show()
		if _hb_sprite:
			_hb_sprite.show()
		_hb_visibility_timer = health_bar_visible_time
	elif _hb_has_lost_health():
		if _hb_visibility_timer > 0.0:
			_hb_visibility_timer -= delta
			_hb_ui.show()
			if _hb_sprite:
				_hb_sprite.show()
		else:
			_hb_ui.hide()
			if _hb_sprite:
				_hb_sprite.hide()
	else:
		_hb_ui.hide()
		if _hb_sprite:
			_hb_sprite.hide()

func _hb_billboard() -> void:
	if _hb_pivot == null:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var look_pos      := cam.global_position
	look_pos.y         = _hb_pivot.global_position.y
	_hb_pivot.look_at(look_pos, Vector3.UP)

func _hb_is_chasing() -> bool:
	return active and is_alive()

func _hb_has_lost_health() -> bool:
	return current_health < max_health

func _on_health_changed_hb(new_health: float, _max: float) -> void:
	if _hb_ui == null:
		return
	var delta_hp := _hb_last_health - new_health
	_hb_last_health = new_health
	if delta_hp > 0.0:
		_hb_ui.take_damage(delta_hp)
	elif delta_hp < 0.0:
		_hb_ui.heal(-delta_hp)
	_hb_visibility_timer = health_bar_visible_time

func _on_died_hb() -> void:
	if _hb_ui:
		_hb_ui.hide()

# ── Navegación ────────────────────────────────────────────────
func _setup_navigation() -> void:
	_configure_nav_agent()

func _configure_nav_agent() -> void:
	nav_agent.path_desired_distance   = 1.5
	nav_agent.target_desired_distance = 1.5
	await get_tree().physics_frame
	await get_tree().physics_frame
	if target and is_instance_valid(target):
		nav_agent.target_position = target.global_position

func _find_player() -> void:
	target = get_tree().get_first_node_in_group("player")

# ── Loop principal ────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if not is_alive():
		return

	if _should_skip_physics():
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		move_and_slide()
		return

	if target == null or not is_instance_valid(target):
		_find_player()
		if target == null:
			velocity = Vector3.ZERO
			move_and_slide()
			return

	_tick_timers(delta)
	_apply_gravity(delta)
	_update_active_state()
	_handle_combat()
	_handle_movement()
	move_and_slide()

func _should_skip_physics() -> bool:
	return false

func _tick_timers(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

func _update_active_state() -> void:
	if not is_alive():
		return
	var dist = global_position.distance_to(target.global_position)
	if dist > max_distance:
		active       = false
		is_attacking = false
		nav_agent.target_position = spawn_position
	else:
		active = true
		nav_agent.target_position = target.global_position

func _handle_combat() -> void:
	var dist     = global_position.distance_to(target.global_position)
	var in_range = active and dist <= attack_distance

	if in_range and not is_attacking and attack_timer <= 0.0:
		_start_attack()
	elif is_attacking:
		_face_target()
		_brake()
	elif in_range and attack_timer > 0.0:
		_face_target()
		_brake()
		_play_if_not(anim_idle)

func _start_attack() -> void:
	is_attacking = true
	_brake()
	_face_target()
	anim_player.play(anim_attack)

func _handle_movement() -> void:
	if is_attacking:
		return
	if not nav_agent.is_navigation_finished():
		var next      = nav_agent.get_next_path_position()
		var direction = (next - global_position)
		direction.y   = 0.0

		if direction.length() > 0.01:
			var dir_n = direction.normalized()
			if active:
				velocity.x = dir_n.x * move_speed
				velocity.z = dir_n.z * move_speed
				_play_if_not(anim_run)
				_face_target()
			else:
				velocity.x = dir_n.x * walk_speed
				velocity.z = dir_n.z * walk_speed
				_play_if_not(anim_walk)
				_face_direction(global_position + direction)
	else:
		_brake()
		_play_if_not(anim_idle)

func _brake() -> void:
	velocity.x = move_toward(velocity.x, 0, move_speed)
	velocity.z = move_toward(velocity.z, 0, move_speed)

func _face_target() -> void:
	if target and is_instance_valid(target):
		_face_direction(target.global_position)

func _face_direction(world_pos: Vector3) -> void:
	var look_pos = world_pos
	look_pos.y   = global_position.y
	look_at(look_pos, Vector3.UP)
	rotate_y(deg_to_rad(180))

func _play_if_not(anim_name: String) -> void:
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)

# ── Vida y daño ───────────────────────────────────────────────
func take_damage(amount: float) -> void:
	if not is_alive():
		return
	current_health = clamp(current_health - amount, 0.0, max_health)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		die()

func heal(amount: float) -> void:
	current_health = clamp(current_health + amount, 0.0, max_health)
	health_changed.emit(current_health, max_health)

func is_alive() -> bool:
	return current_health > 0

func die() -> void:
	died.emit()
	active       = false
	is_attacking = false
	velocity     = Vector3.ZERO

	if attack_hitbox:
		attack_hitbox.monitoring  = false
		attack_hitbox.monitorable = false
	collision.disabled = true
	anim_player.play(anim_death)

	await anim_player.animation_finished
	await get_tree().create_timer(60.0).timeout
	queue_free()

# ── Animaciones ───────────────────────────────────────────────
func _on_animation_finished(anim_name: String) -> void:
	if not is_alive():
		return

	if anim_name == anim_attack:
		_apply_attack_hit()
		anim_player.play(anim_attack_back)
	elif anim_name == anim_attack_back:
		attack_timer = attack_cooldown
		is_attacking = false
		_play_if_not(anim_idle)

	_on_animation_finished_extra(anim_name)

func _apply_attack_hit() -> void:
	if target == null or not is_instance_valid(target):
		return
	var bodies = attack_hitbox.get_overlapping_bodies()
	if target in bodies:
		var manager = target.get_node_or_null("PlayerManager")
		if manager and manager.has_method("take_damage"):
			manager.take_damage(attack_damage)

func _on_animation_finished_extra(_anim_name: String) -> void:
	pass
