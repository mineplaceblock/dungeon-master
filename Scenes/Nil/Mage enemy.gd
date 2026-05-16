extends CharacterBody3D

const SPEED = 5.0
const WALK_SPEED = 2.5
const MAX_DISTANCE = 20.0
const ATTACK_DISTANCE = 2
const ATTACK_COOLDOWN = 0.5

static var nav_baked: bool = false

@onready var navAgent = $NavigationAgent3D2
@onready var target = $"../../ProtoController"
@onready var navRegion = get_tree().get_root().find_child("NavigationRegion3D", true, false)
@onready var animPlayer = $AnimationPlayer3
@onready var attack_hitbox = $AttackHitbox
var spawn_position: Vector3
var active: bool = true
var is_attacking: bool = false
var attack_timer: float = 0.0

func _ready():
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(60)
	
	spawn_position = global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	# Solo hornear una vez entre todos los enemigos
	if not nav_baked:
		nav_baked = true
		navRegion.bake_finished.connect(_on_bake_finished)
		navRegion.bake_navigation_mesh()
	else:
		# Si ya está horneado, inicializar directamente
		navAgent.path_desired_distance = 1.5
		navAgent.target_desired_distance = 1.5
		await get_tree().physics_frame
		await get_tree().physics_frame
		navAgent.target_position = target.global_position

	animPlayer.animation_finished.connect(_on_animation_finished)
	animPlayer.play("Descansar")

func _on_bake_finished():
	navAgent.path_desired_distance = 1.5
	navAgent.target_desired_distance = 1.5
	await get_tree().physics_frame
	await get_tree().physics_frame
	navAgent.target_position = target.global_position

			
func _physics_process(delta):
	var distance_to_player = global_position.distance_to(target.global_position)

	if attack_timer > 0.0:
		attack_timer -= delta

	if distance_to_player > MAX_DISTANCE:
		active = false
		is_attacking = false
		navAgent.target_position = spawn_position
	else:
		active = true
		navAgent.target_position = target.global_position

	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	var in_attack_range = active and distance_to_player <= ATTACK_DISTANCE

	if in_attack_range and not is_attacking and attack_timer <= 0.0:
		is_attacking = true
		animPlayer.play("Atacar")
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

		var look_target = target.global_position
		look_target.y = global_position.y
		look_at(look_target, Vector3.UP)
		rotate_y(deg_to_rad(180))

	elif is_attacking:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

		var look_target = target.global_position
		look_target.y = global_position.y
		look_at(look_target, Vector3.UP)
		rotate_y(deg_to_rad(180))

	elif in_attack_range and attack_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		if animPlayer.current_animation != "Descansar":
			animPlayer.play("Descansar")

		var look_target = target.global_position
		look_target.y = global_position.y
		look_at(look_target, Vector3.UP)
		rotate_y(deg_to_rad(180))

	elif not navAgent.is_navigation_finished():
		var next = navAgent.get_next_path_position()
		var direction = next - global_position
		direction.y = 0.0

		if direction.length() > 0.01:
			var dir_normalized = direction.normalized()
			if active:
				velocity.x = dir_normalized.x * SPEED
				velocity.z = dir_normalized.z * SPEED
				if animPlayer.current_animation != "Running_A":
					animPlayer.play("Running_A")

				var look_target = target.global_position
				look_target.y = global_position.y
				look_at(look_target, Vector3.UP)
				rotate_y(deg_to_rad(180))
			else:
				velocity.x = dir_normalized.x * WALK_SPEED
				velocity.z = dir_normalized.z * WALK_SPEED
				if animPlayer.current_animation != "Walking_B":
					animPlayer.play("Walking_B")

				var look_target = global_position + direction
				look_target.y = global_position.y
				look_at(look_target, Vector3.UP)
				rotate_y(deg_to_rad(180))
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		if animPlayer.current_animation != "Descansar":
			animPlayer.play("Descansar")

	move_and_slide()


func _on_animation_finished(anim_name):
	if anim_name == "Atacar":
		attack_timer = ATTACK_COOLDOWN
		is_attacking = false

		var bodies = attack_hitbox.get_overlapping_bodies()
		if target in bodies:
			var player_manager = target.get_node("PlayerManager")
			if player_manager:
				player_manager.take_damage(20)
