extends Node3D

@export var rock_amplitude_x := 5.0  # forward-back tilt in degrees
@export var rock_amplitude_z := 3.0  # side-to-side tilt
@export var rock_speed := 1.0        # wave speed multiplier

var time := 0.0

func _process(delta):
	time += delta * rock_speed
	
	# gentle sine wave motion
	var rot_x = sin(time * 1.2) * rock_amplitude_x
	var rot_z = sin(time * 0.9) * rock_amplitude_z
	
	rotation_degrees.x = rot_x
	rotation_degrees.z = rot_z
