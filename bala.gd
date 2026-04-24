extends CharacterBody3D


var speed = 50
const JUMP_VELOCITY = 4.5


func _process(delta):
	position+=transform.basis * Vector3(0,0,speed) * delta
