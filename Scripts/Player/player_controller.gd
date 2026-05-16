# ProtoController v1.0 by Brackeys – modified for PlayerManager integration

extends CharacterBody3D

@export var can_move : bool = true
@export var has_gravity : bool = true
@export var can_jump : bool = true
@export var can_sprint : bool = false
@export var can_freefly : bool = false

@export_group("Speeds")
@export var look_speed : float = 0.002
@export var base_speed : float = 7.0
@export var jump_velocity : float = 4.5
@export var sprint_speed : float = 10.0
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
@export var input_left : String = "LeftMove"
@export var input_right : String = "RightMove"
@export var input_forward : String = "ForwardMove"
@export var input_back : String = "BackwardsMove"
@export var input_jump : String = "Jump"
@export var input_sprint : String = "Sprint"
@export var input_freefly : String = "Fly"

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var freeze : bool = false
var thirdpelson : bool = false

# --- Animation state tracking ---
enum JumpState { NONE, STARTING, AIRBORNE, LANDING }
var jump_state : JumpState = JumpState.NONE
var was_on_floor : bool = true
var jump_hold_timer : float = 0.0          # how long we've been in the air
const JUMP_LONG_THRESHOLD : float = 0.55   # seconds airborne → Long vs Short land

@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var player_manager: Node = $PlayerManager
## Assign your AnimationPlayer node path here
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	add_to_group("player")
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	player_manager.player_died.connect(_on_player_died)
	# Connect animation finished signal for one-shot anims
	anim_player.animation_finished.connect(_on_animation_finished)
	anim_player.play("Descans")

func _unhandled_input(event: InputEvent) -> void:
	if freeze:
		return

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()

	if Input.is_action_just_pressed("cambiar_escena"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://Minigames/Tic Tac Toe/tictactoe.tscn")
		queue_free()
		
	
	if Input.is_action_just_pressed("mapsecreto"):
		get_tree().change_scene_to_file("res://addons/inventory-system-demos/fps/fps_demo.tscn")
		queue_free()
	
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)

	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

	if Input.is_action_just_pressed("debugk"):
		if thirdpelson:
			$Head/Camera3D.make_current()
			thirdpelson = false
		else:
			$ThirdPersonCamera.make_current()
			thirdpelson = true

func _physics_process(delta: float) -> void:
	if freeze:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return

	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta

	# --- Jump input → trigger Jump_Start ---
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			velocity.y = jump_velocity
			jump_state = JumpState.STARTING
			jump_hold_timer = 0.0
			_play_anim("Jump_Start")

	# Sprint stamina
	if can_sprint and Input.is_action_pressed(input_sprint):
		var stamina_consumed: bool = player_manager.consume_stamina(player_manager.stamina_drain_rate * delta)
		move_speed = sprint_speed if stamina_consumed else base_speed
	else:
		move_speed = base_speed

	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.y = 0

	move_and_slide()

	# --- Track airborne time ---
	if not is_on_floor():
		jump_hold_timer += delta

	# --- Detect landing ---
	var just_landed : bool = (not was_on_floor) and is_on_floor()
	was_on_floor = is_on_floor()

	_update_animations(just_landed)

# ─────────────────────────────────────────────
#  ANIMATION STATE MACHINE
# ─────────────────────────────────────────────
func _update_animations(just_landed: bool) -> void:
	# Don't interrupt one-shot anims that are still playing
	var cur : String = anim_player.current_animation

	# ── DEATH (highest priority, handled by signal) ──
	if freeze and (cur == "Mort" or cur == "Mort posi"):
		return

	# ── LANDING ──
	if just_landed:
		jump_state = JumpState.LANDING
		if jump_hold_timer >= JUMP_LONG_THRESHOLD:
			_play_anim("Jump_Full_Long")
		else:
			_play_anim("Jump_Full_Short")
		jump_hold_timer = 0.0
		return

	# ── IN THE AIR ──
	if not is_on_floor():
		match jump_state:
			JumpState.STARTING:
				pass  # Wait for Jump_Start to finish (handled in _on_animation_finished)
			JumpState.AIRBORNE:
				if cur != "Jump_Idle":
					_play_anim("Jump_Idle")
		return

	# ── ON THE FLOOR ──
	# If we just finished landing, let the landing anim finish first
	if jump_state == JumpState.LANDING:
		return

	jump_state = JumpState.NONE

	var horizontal_speed : float = Vector2(velocity.x, velocity.z).length()
	var is_moving : bool = horizontal_speed > 0.5
	var is_sprinting : bool = can_sprint and Input.is_action_pressed(input_sprint) and horizontal_speed > 0.5

	if is_sprinting:
		# Alternate Running_A / Running_B on each cycle
		if cur != "Running_A" and cur != "Running_B":
			_play_anim("Running_A")
	elif is_moving:
		# Cycle through walking variants for natural feel
		if cur != "Walking_A" and cur != "Walking_B" and cur != "Walking_C":
			_play_anim("Walking_A")
	else:
		if cur != "Descans":
			_play_anim("Descans")

# Called when a one-shot animation finishes
func _on_animation_finished(anim_name: String) -> void:
	match anim_name:
		"Jump_Start":
			# Now truly airborne → loop Jump_Idle
			jump_state = JumpState.AIRBORNE
			_play_anim("Jump_Idle")

		"Jump_Full_Long", "Jump_Full_Short", "Jump_Land":
			jump_state = JumpState.NONE
			_play_anim("Descans")

		"Running_A":
			_play_anim("Running_B")
		"Running_B":
			_play_anim("Running_A")

		"Walking_A":
			_play_anim("Walking_B")
		"Walking_B":
			_play_anim("Walking_C")
		"Walking_C":
			_play_anim("Walking_A")

		"Mort", "Mort posi":
			pass  # Stay on death pose

# ─────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────
func _play_anim(anim_name: String) -> void:
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)

func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false

func _on_player_died():
	freeze = true
	$Head/Arm.visible = false
	release_mouse()
	$ThirdPersonCamera.make_current()
	thirdpelson = true
	_play_anim("Mort")
