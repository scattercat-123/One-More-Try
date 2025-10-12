extends Control

func _process(_delta: float) -> void:
	if get_tree().current_scene.is_in_group("Tut_cutscene"):
		visible = false
	else:
		visible = true
