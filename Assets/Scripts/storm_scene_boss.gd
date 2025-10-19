extends Node3D

func play_lightning_sound():
	var rand_sound = randi_range(0,2)
	if rand_sound == 0:
		$lightning_1.play()
	elif rand_sound == 1:
		$lightning_2.play()
