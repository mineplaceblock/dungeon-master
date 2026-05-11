# IA RANDOM + DETECCIÓN DE BORDES
# GODOT 4

extends CharacterBody3D

@export var velocidad := 4.0
@export var gravedad := 20.0
@export var distancia_borde := 2.0
@export var rango_movimiento := 25.0

var objetivo := Vector3.ZERO
var direccion := Vector3.ZERO
var origen := Vector3.ZERO

@onready var ray_frente: RayCast3D = $RayFrente

func _ready():
	randomize()
	origen = global_position
	nuevo_objetivo()

func _physics_process(delta):

	# =====================
	# GRAVEDAD
	# =====================
	if not is_on_floor():
		velocity.y -= gravedad * delta

	# =====================
	# DIRECCIÓN AL OBJETIVO
	# =====================
	direccion = (objetivo - global_position).normalized()
	direccion.y = 0

	# =====================
	# ROTAR PERSONAJE
	# =====================
	if direccion.length() > 0.1:
		look_at(global_position + direccion, Vector3.UP)

	# =====================
	# RAYCAST DELANTE
	# =====================
	ray_frente.target_position = direccion * distancia_borde + Vector3.DOWN * 4

	# =====================
	# SI NO HAY SUELO → PARAR Y GIRAR
	# =====================
	if not ray_frente.is_colliding():

		# Frenar
		velocity.x = 0
		velocity.z = 0

		# Nuevo camino aleatorio
		nuevo_objetivo()

	else:

		# Movimiento normal
		velocity.x = direccion.x * velocidad
		velocity.z = direccion.z * velocidad

	move_and_slide()

	# =====================
	# SI LLEGA → NUEVO DESTINO
	# =====================
	if global_position.distance_to(objetivo) < 2:
		nuevo_objetivo()

func nuevo_objetivo():
	var x = randf_range(-rango_movimiento, rango_movimiento)
	var z = randf_range(-rango_movimiento, rango_movimiento)
	print(x,z)
	objetivo = origen + Vector3(x, 0, z)
