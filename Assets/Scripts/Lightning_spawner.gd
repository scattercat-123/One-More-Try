extends Node3D

@export var lightning_scene: PackedScene = preload("res://Assets/Scenes/lightning.tscn")
@export var spawn_rate: float = 2.0
@export var spawn_height: float = 20.0

var timer: float = 0.0

func _process(delta):
	timer += delta
	if timer >= spawn_rate:
		spawn_lightning()
		timer = 0.0

func spawn_lightning():
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return
	if randi() % 2 == 0:
		$thunder.play()
	else:
		$thunder2.play()

	var screen_x = randf()  # 0 → left, 1 → right
	var screen_y = 0.0      # top of the screen

	# Convert screen coordinates to world
	var from = cam.project_ray_origin(Vector2(screen_x * cam.get_viewport().size.x, screen_y * cam.get_viewport().size.y))
	var dir = cam.project_ray_normal(Vector2(screen_x * cam.get_viewport().size.x, screen_y * cam.get_viewport().size.y))

	# Instantiate lightning
	var lightning = lightning_scene.instantiate()

	# Randomize scale
	var scale_factor = 4.0 + randf() * 5.0  # random between 3 and 7
	lightning.scale = Vector3.ONE * scale_factor

	# Position in front of camera
	lightning.position = from + dir * spawn_height
	add_child(lightning)
