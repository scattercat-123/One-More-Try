extends Camera3D

@export var shake_intensity := 0.2
@export var shake_duration := 0.5
@export var shake_speed := 30.0

var shaking := false
var shake_timer := 0.0
var original_pos := Vector3.ZERO
var slam_shake_active := false
var rush_shake_active = false

func _ready():
	original_pos = position

func _process(delta):
	if shaking:
		shake_timer -= delta
		if shake_timer > 0:
			position = original_pos + Vector3(
				(randf() - 0.5) * 2.0 * shake_intensity,
				(randf() - 0.5) * 2.0 * shake_intensity,
				(randf() - 0.5) * 2.0 * shake_intensity
			)
		else:
			shaking = false
			position = original_pos

	if Global.boss_1_state == "slam":
		if not slam_shake_active:
			slam_shake_active = true
			_start_slam_shake()
	else:
		slam_shake_active = false
	if Global.boss_1_state == "rush_attack":
		if not rush_shake_active:
			rush_shake_active = true
			_start_rush_shake()
	else:
		rush_shake_active = false


func start_earthquake(intensity := 0.2, duration := 0.5):
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
	shaking = true


func _start_slam_shake():
	await get_tree().create_timer(0.233).timeout
	if Global.boss_1_state == "slam":
		start_earthquake(0.02, 0.1)
		_start_slam_shake()
	else:
		slam_shake_active = false

func _start_rush_shake():
	start_earthquake(0.02, 0.1)
	await get_tree().create_timer(0.25).timeout
	start_earthquake(0.02, 0.1)
	await get_tree().create_timer(0.25).timeout
	start_earthquake(0.02, 0.1)
	await get_tree().create_timer(0.5).timeout
	start_earthquake(0.02, 0.1)
	await get_tree().create_timer(0.25).timeout
	start_earthquake(0.02, 0.1)
	await get_tree().create_timer(0.5).timeout
	start_earthquake(0.02, 0.1)
	await get_tree().create_timer(0.5).timeout
	start_earthquake(0.02, 0.1)
	await get_tree().create_timer(0.25).timeout
	start_earthquake(0.02, 0.1)
	if Global.boss_1_state == "rush_attack":
		_start_rush_shake()
	else:
		rush_shake_active = false
