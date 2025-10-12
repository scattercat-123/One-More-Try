extends Node3D

@export var speed: float = 7.0
var direction: Vector3 = Vector3.ZERO

func _process(delta: float) -> void:
	global_position += direction * speed * delta

func _ready():
	await get_tree().create_timer(0.8).timeout
	queue_free()
