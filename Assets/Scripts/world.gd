extends Node3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_bar: ProgressBar = $player/GUI/GUI_BAR/health_bar
@onready var stamina_bar: ProgressBar = $player/GUI/GUI_BAR/stamina_bar
@onready var player_camera: Camera3D = $player/Camera3D
@onready var cutscene_camera: Camera3D = $cutscene_camera
@onready var markers_parent: Node3D = $Spawning_markers
@export var fireball_scene: PackedScene = preload("res://Assets/Scenes/fireball_enemy.tscn")
@export var possessed_scene: PackedScene = preload("res://Assets/Scenes/possessed_enemy.tscn")

var enemies_per_wave := [10, 20, 35]
var enemies_chance_spawn := [60, 40]
# it's percentage - fireball, possessed respectively.
var enemies_per_wave_chance_to_spawn = 10

var current_enemies := []
var markers: Array = []
var once = true

# spawn control state:
var prev_enemies_left := -1
var last_wave_spawned := 0       # which wave we last spawned (0 = none)
@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	Dialogic.start("woke_up_from_island")
	Dialogic.signal_event.connect(signaling)
	health_bar.value = 100
	stamina_bar.value = 100
	player_camera.make_current()
	randomize()
	markers = markers_parent.get_children()

	# disable the timer auto-start if it was
	if spawn_timer.is_stopped() == false:
		spawn_timer.stop()

	# initialize prev_enemies_left so first transition detection works
	prev_enemies_left = Global.enemies_left

func _process(_delta: float) -> void:
	# one-time setup for wave 1 (your previous logic)
	if Global.wave == 1 and once == true:
		Global.enemies_left = 2
		once = false

	# detect a wave-completion transition: previously >0, now 0
	if prev_enemies_left > 0 and Global.enemies_left == 0:
		# a wave has just ended
		# increment wave only once when a wave completes
		Global.wave = Global.wave + 1

		# start spawning only if the new wave is >= 2
		if Global.wave >= 2:
			# start a short delay before spawning the next wave (gives you time to show UI)
			spawn_timer.start()

	# update prev for next tick
	prev_enemies_left = Global.enemies_left

func signaling(arg):
	if arg == "cough":
		await get_tree().create_timer(0.5).timeout
		Global.damage = 30
		$Damage_Audio.play()
		$Damager.visible = true
		await  get_tree().create_timer(0.3).timeout
		$Damager.visible = false

	if arg == "monster_saw":
		if Global.debug_mode == false:
			animation_player.play("monster_saw")
			cutscene_camera.make_current()
		await get_tree().create_timer(8.0).timeout
		player_camera.make_current()

func spawn_fireball_enemy_at(marker: Node3D):
	var fb = fireball_scene.instantiate()
	# add to the main scene root to match player/enemies location
	get_tree().current_scene.add_child(fb)
	fb.global_transform = marker.global_transform
	fb.scale = Vector3(2, 2, 2)
	current_enemies.append(fb)

func spawn_possessed_enemy_at(marker: Node3D):
	var ps = possessed_scene.instantiate()
	get_tree().current_scene.add_child(ps)
	ps.global_transform = marker.global_transform
	ps.scale = Vector3(2, 2, 2)
	current_enemies.append(ps)

func spawn_wave(wave_num: int):
	# do not spawn same wave twice
	if last_wave_spawned == wave_num:
		return

	var total_enemies = enemies_per_wave[min(wave_num - 1, enemies_per_wave.size() - 1)]

	# calculate modified spawn chances
	var modified_chances = enemies_chance_spawn.duplicate()
	for i in range(modified_chances.size()):
		# harder enemies (to the right) increase their spawn chance each wave
		var difficulty_factor = i * enemies_per_wave_chance_to_spawn * (wave_num - 1)
		modified_chances[i] += difficulty_factor

	# normalize chances (so they always add to 100)
	var total = 0.0
	for chance in modified_chances:
		total += chance
	for i in range(modified_chances.size()):
		modified_chances[i] = (modified_chances[i] / total) * 100.0

	# spawn loop
	for i in range(total_enemies):
		var idx = randi() % markers.size()
		var marker: Node3D = markers[idx]
		var roll = randf() * 100.0

		if roll < modified_chances[0]:
			spawn_fireball_enemy_at(marker)
		else:
			spawn_possessed_enemy_at(marker)

	# record that we've spawned this wave and set enemies_left
	last_wave_spawned = wave_num
	Global.enemies_left = total_enemies

func _on_spawn_timer_timeout() -> void:
	# only spawn if wave >= 2 (you requested spawn to start from wave 2)
	if Global.wave >= 2 and Global.wave <= enemies_per_wave.size():
		spawn_wave(Global.wave)
	# do NOT restart the timer here — starting is controlled from _process when a wave finishes
