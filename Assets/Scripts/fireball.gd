extends Node3D

@export var speed: float = 7.0
var direction: Vector3 = Vector3.ZERO

func _process(delta: float) -> void:
	global_position += direction * speed * delta

func _ready():
	pass
	#queue_free()
