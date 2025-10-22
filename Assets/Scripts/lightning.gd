extends Node3D

func _ready() -> void:
	if not Global.wave > 1:
		$AnimatedSprite3D.position.y = 0
	else:
		var rand_sound = randi_range(0,1)
		if rand_sound == 1:
			$thunder.play()
		else:
			$thunder2.play()
	await get_tree().create_timer(0.45).timeout
	$Lightning/CollisionShape3D.disabled = false
	await get_tree().create_timer(0.1).timeout
	queue_free()
