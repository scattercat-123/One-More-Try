extends Control
var once = false

func _process(_delta: float) -> void:
	if get_tree().current_scene.is_in_group("Tut_cutscene"):
		visible = false
	else:
		visible = true
	if Global.wave > 4 and once == false:
		once = true
		$AnimationPlayer.play("Hide_boss_1_health_bar")
	if Global.wave == 4:
		$GUI_BAR/boss_health_bar.visible = true
		
		$GUI_BAR/boss_health_bar.value = Global.boss_1_health_value
	if not Global.wave == 4:
		$GUI_BAR/boss_health_bar.visible = false
