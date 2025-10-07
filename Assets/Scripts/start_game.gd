extends Sprite2D
@onready var hover: AudioStreamPlayer = $"../../AudioStreamPlayer"
@export var hover_multiplier: float = 1.05
@export var speed: float = 6.0
@onready var bg_music: AudioStreamPlayer = $"../../../AudioStreamPlayer"
@onready var zoomy: AnimationPlayer = $"../../AnimationPlayer"
@onready var scene_transition: AnimationPlayer = $"../../../Scene transition/AnimationPlayer"

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

func _on_start_button_area_mouse_entered() -> void:
	mouse = true
	target_scale = normal_scale * hover_multiplier
	hover.play()

func _on_start_button_area_mouse_exited() -> void:
	target_scale = normal_scale
	mouse = false

func _start_transition() -> void:
	zoomy.play("zooom_start_game")
	_continue_transition()

func _continue_transition() -> void:
	await get_tree().create_timer(0.5).timeout
	scene_transition.play("change")
	await scene_transition.animation_finished
	get_tree().change_scene_to_file("res://Assets/Scenes/tutorial_cutscene.tscn")
