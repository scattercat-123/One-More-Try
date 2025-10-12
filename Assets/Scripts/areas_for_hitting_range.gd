extends Node3D

@onready var collision_shape_3d: CollisionShape3D = $player_hitbox/CollisionShape3D
var default_scale: Vector3
func _ready() -> void:
	default_scale = collision_shape_3d.scale
func _process(_delta: float) -> void:
	var range_multiplier = 1.0 + (Global.extra_range * 0.1)
	collision_shape_3d.scale = default_scale * range_multiplier
