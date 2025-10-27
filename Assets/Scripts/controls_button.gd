extends Sprite2D
@onready var hover: AudioStreamPlayer = $"../../AudioStreamPlayer"
@export var hover_multiplier: float = 1.05
@export var speed: float = 6.0
var controls_menu_opened = false
var normal_scale: Vector2
var target_scale: Vector2
var mouse = false
var hover_close_button = false
func _ready() -> void:
	normal_scale = scale
	target_scale = normal_scale

func _process(delta: float) -> void:
	scale = scale.lerp(target_scale, delta * speed)
	if mouse == true and Input.is_action_just_pressed("click") and controls_menu_opened == false:
		$"../../../AnimationPlayer".play("control_open")
		controls_menu_opened = true
		$"../../controls_menu".visible = true
	if hover_close_button == true and Input.is_action_just_pressed("click") and controls_menu_opened == true:
		$"../../../AnimationPlayer".play("control_close")
		controls_menu_opened = false

func _on_controls_button_area_mouse_entered() -> void:
	mouse = true
	target_scale = normal_scale * hover_multiplier
	$"../../AudioStreamPlayer".play()

func _on_controls_button_area_mouse_exited() -> void:
	target_scale = normal_scale
	mouse = false

func _on_close_mouse_entered() -> void:
	hover_close_button = true
	$"../../AudioStreamPlayer".play()


func _on_close_mouse_exited() -> void:
	hover_close_button = false
