extends Label
@onready var boss_health_bar: ProgressBar = $".."

func _process(delta: float) -> void:
	var value = boss_health_bar.value
	text = "Boss Health: " + str(value) + "/" + str(boss_health_bar.max_value)
