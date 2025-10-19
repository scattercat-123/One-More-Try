extends Camera3D

@export var shake_intensity := 0.2
@export var shake_duration := 0.5
@export var shake_speed := 30.0

var shaking := false
var shake_timer := 0.0
var original_pos := Vector3.ZERO

func _ready():
	original_pos = position

func _process(delta):
	if shaking:
		shake_timer -= delta
		if shake_timer > 0:
			position = original_pos + Vector3(
				(randf() - 0.5) * 2.0 * shake_intensity,
				(randf() - 0.5) * 2.0 * shake_intensity,
				(randf() - 0.5) * 2.0 * shake_intensity
			)
		else:
			shaking = false
			position = original_pos

func start_earthquake(intensity := 0.2, duration := 0.5):
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
	shaking = true
