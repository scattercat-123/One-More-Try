extends Sprite2D
@onready var hover: AudioStreamPlayer = $"../hover"
@export var hover_multiplier: float = 1.05
@export var speed: float = 6.0
@onready var scene_transition: AnimationPlayer = $"../AnimationPlayer"

var normal_scale: Vector2
var target_scale: Vector2
var mouse = false

func _ready() -> void:
	normal_scale = scale
	target_scale = normal_scale

func _process(delta: float) -> void:
	scale = scale.lerp(target_scale, delta * speed)
	if mouse == true and Input.is_action_just_pressed("click"):
		_start_transition()

func _on_button_mouse_entered() -> void:
	mouse = true
	target_scale = normal_scale * hover_multiplier
	hover.play()

func _on_button_mouse_exited() -> void:
	target_scale = normal_scale
	mouse = false

func _start_transition() -> void:
	scene_transition.play("change")
	await scene_transition.animation_finished
	get_tree().change_scene_to_file("res://Assets/Scenes/platformer.tscn")
