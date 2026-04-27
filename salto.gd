extends Node3D  # o CharacterBody2D, Control, etc.

func _ready():
	$AnimationPlayer.play("mixamo_com")
