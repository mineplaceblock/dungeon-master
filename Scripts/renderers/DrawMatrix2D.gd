@tool
extends Node3D

var default_colors: Array[Color] = [
	Color.DARK_BLUE,
	Color("#e5d9c2"),
	Color("#725428"),
	Color("#b5ba61"),
	Color("#7c8d4c"),
	Color.DARK_OLIVE_GREEN
]

func draw_matrix_texture(matrix: Array, colors: Array[Color] = default_colors) -> ImageTexture:
	var height: int = matrix.size()
	var width: int = matrix[0].size()
	
	var image: Image = Image.create_empty(width, height, false, Image.FORMAT_RGB8)
	
	for y in range(height):
		for x in range(width):
			var cell: int = matrix[y][x]
			var color: Color = Color.HOT_PINK
			if cell < colors.size():
				color = colors[cell]
			image.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(image)

func draw_matrix(matrix: Array, colors: Array[Color] = default_colors, texture_scale: float = 1.0):
	for child in get_children():
		child.queue_free()
	
	var height: int = matrix.size()
	var width: int = matrix[0].size()
	
	var texture: ImageTexture = draw_matrix_texture(matrix, colors)
	
	var mesh_instance := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(width * texture_scale, height * texture_scale)
	mesh_instance.mesh = quad
	
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mesh_instance.material_override = material
	
	mesh_instance.position = Vector3(width / 2.0 * texture_scale, 0.0, height / 2.0 * texture_scale)
	mesh_instance.rotation_degrees = Vector3(-90, 0, 0)
	
	add_child(mesh_instance)

func draw_heightmap(matrix: Array):
	for child in get_children():
		child.queue_free()
		
	var height: int = matrix.size()
	var width: int = matrix[0].size()
	
	var image: Image = Image.create_empty(width, height, false, Image.FORMAT_RGB8)
	
	var highest_value: int = -9999
	var lowest_value: int = 9999
	
	for y in range(height):
		for x in range(width):
			var cell: int = matrix[y][x]
			if cell < lowest_value:
				lowest_value = cell
			if cell > highest_value:
				highest_value = cell
	
	for y in range(height):
		for x in range(width):
			var cell: int = matrix[y][x]
			var normalized_value: float = float(cell - lowest_value) / float(highest_value - lowest_value)
			var color := Color(normalized_value, normalized_value, normalized_value)
			image.set_pixel(x, y, color)
	
	var texture := ImageTexture.create_from_image(image)
	
	var mesh_instance := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(width, height)
	mesh_instance.mesh = quad
	
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mesh_instance.material_override = material
	
	mesh_instance.position = Vector3(width / 2.0, 0.0, height / 2.0)
	mesh_instance.rotation_degrees = Vector3(-90, 0, 0)
	
	add_child(mesh_instance)
