extends Node3D

@export var sprite_scene: PackedScene = preload("res://Assets/Scenes/wind.tscn")
@export var spawn_distance: float = 20.0
@export var spawn_rate: float = 0.5  # Seconds between spawns

var timer: float = 0.0

func _process(delta):
	timer += delta
	if timer >= spawn_rate:
		spawn_sprite()
		timer = 0.0

func spawn_sprite():
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return

	# Random screen edge (0=top,1=bottom,2=left,3=right)
	var edge = randi() % 4
	var x = 0.0
	var y = 0.0
	match edge:
		0: x = randf(); y = 0.0
		1: x = randf(); y = 1.0
		2: x = 0.0; y = randf()
		3: x = 1.0; y = randf()

	# Convert viewport coordinates to world space
	var from = cam.project_ray_origin(Vector2(x * cam.get_viewport().size.x, y * cam.get_viewport().size.y))
	var dir = cam.project_ray_normal(Vector2(x * cam.get_viewport().size.x, y * cam.get_viewport().size.y))
	
	# Instantiate wind sprite
	var sprite_instance = sprite_scene.instantiate()
	sprite_instance.position = from + dir * spawn_distance
	
	# Random scale
	var scale_value = 0.8 + randf()
	sprite_instance.scale = Vector3.ONE * scale_value

	# Random movement direction in XZ plane
	if sprite_instance.has_method("set_direction"):
		var move_dir = Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized()
		sprite_instance.set_direction(move_dir)

	add_child(sprite_instance)
