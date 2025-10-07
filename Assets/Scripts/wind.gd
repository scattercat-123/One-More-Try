extends Node3D
@onready var sprite3d: AnimatedSprite3D = $AnimatedSprite3D  # Only used for animation control

@export var speed_range: Vector2 = Vector2(5.0, 8.0)
var direction: Vector3 = Vector3.ZERO
var speed: float = 0.0

func set_direction(dir: Vector3):
	direction = dir.normalized()
	speed = randf() * (speed_range.y - speed_range.x) + speed_range.x
	if direction.x > 0:
		scale.x = -abs(scale.x)
	else:
		scale.x = abs(scale.x)
func _process(delta):
	if direction != Vector3.ZERO:
		translate(direction * speed * delta)
