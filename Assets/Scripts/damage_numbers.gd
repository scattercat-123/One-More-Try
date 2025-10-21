extends Node3D
func display_number(value: int, position: Vector3):
	var number = Label3D.new()
	number.outline_size = 5
	number.scale = Vector3(1.3, 1.3, 1.3)
	number.text = "-" + str(value)
	number.global_position = position
	number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	number.modulate = Color("#FF2222")

	add_child(number)

	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(number, "global_position:y", position.y + 1, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(number, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	
	await tween.finished
	number.queue_free()

func display_heal_number(value: int, position: Vector3):
	var number = Label3D.new()
	number.outline_size = 5
	number.scale = Vector3(1.3, 1.3, 1.3)
	number.text = "+" + str(value)
	number.global_position = position
	number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	number.modulate = Color("#11d111")

	add_child(number)

	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(number, "global_position:y", position.y + 1, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(number, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	
	await tween.finished
	number.queue_free()
