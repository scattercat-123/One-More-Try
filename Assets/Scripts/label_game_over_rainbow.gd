extends Label

var hue: float = 0.0
@export var speed: float = 0.5

func _process(delta: float) -> void:
	hue += delta * speed
	if hue > 1.0:
		hue -= 1.0
	modulate = Color.from_hsv(hue, 1.0, 1.0)
