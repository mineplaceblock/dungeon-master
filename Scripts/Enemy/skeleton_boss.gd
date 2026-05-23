# boss.gd
class_name Boss
extends CharacterBase

const PILLAR_COOLDOWN       = 8.0
const PILLAR_TPOSE_DURATION = 1.5

@export var pillar_scene: PackedScene

var _pillar_timer: float = 4.0
var _doing_pillar: bool  = false

func _on_ready_extra() -> void:
	attack_damage   = 35.0
	move_speed      = 5.0
	attack_distance = 2.5
	setup_health(500.0)

func _should_skip_physics() -> bool:
	return _doing_pillar

func _physics_process(delta: float) -> void:
	if not _doing_pillar:
		_pillar_timer -= delta
		if _pillar_timer <= 0.0 and active and not is_attacking:
			_spawn_pillar()
			return
	super._physics_process(delta)

func _spawn_pillar() -> void:
	if target == null or not is_instance_valid(target):
		return
	if pillar_scene == null:
		push_error("Boss: pillar_scene no asignada en el inspector")
		return

	_doing_pillar = true
	is_attacking  = true
	anim_player.play("T-Pose")

	await get_tree().create_timer(PILLAR_TPOSE_DURATION).timeout

	if not is_instance_valid(target):
		_doing_pillar = false
		is_attacking  = false
		return

	var pillar = pillar_scene.instantiate() as Node3D
	get_tree().current_scene.add_child(pillar)
	var spawn_pos          = target.global_position
	spawn_pos.y           -= 4.0
	pillar.global_position = spawn_pos
	pillar.target_y        = target.global_position.y

	await get_tree().create_timer(2.0).timeout

	_doing_pillar = false
	is_attacking  = false
	_pillar_timer = PILLAR_COOLDOWN
	anim_player.play(anim_idle)
