extends CharacterBody3D
@onready var sprite: AnimatedSprite3D
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var damage_numbers_origin: Node3D = $damage_numbers_origin
@onready var label: Label3D = $Label3D
@export var speed: float = 1
@onready var spike_area: CollisionShape3D = $spike_area/CollisionShape3D
var health: int = 60
var rand_colour
var player
var colour
var enraged = false
var displayed_health := 60
var state: String = "idle"
const STATE_LENGTH := 4.0
var state_locked := false
var did_attack := false
var is_slamming := false
var is_attacking := false
var timer_for_showing_path := 1.5

func _ready() -> void:
	rand_colour = randi_range(0, 3)
	colour = get_child(rand_colour).name
	sprite = get_child(rand_colour)
	sprite.visible= true
	player = get_tree().get_first_node_in_group("Player")
	state = "chase"
	Global.enemies_left += 1

func _process(delta: float) -> void:
	displayed_health = lerp(displayed_health, health, delta * 10.0)
	$Health_bar_viewport/health_bar.value = displayed_health
	if not state_locked:
		if state == "idle":
			_update_idle()
		elif state == "chase":
			_update_chase()
		elif state == "attack":
			shoot()
		elif state == "spike":
			spike()
		label.text = state
	if state== "chase":
		var player_dir = get_player_direction()
		match player_dir:
			"up":
				sprite.play("walk_up")
			"down":
				sprite.play("walk_down")
			"right", "up_right", "down_right":
				sprite.play("walk_right")
	if health < 60 and not enraged:
		enraged = true
	if health <= 0 or global_position.y <= -1:
		visible = false
		get_tree().call_group("Spawner", "on_enemy_died")
		queue_free()
	if state == "idle":
		$Health_Bar.position.y = 0.179
	else:
		$Health_Bar.position.y = 0.12
		
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if is_instance_valid(player):
		sprite.rotation_degrees.y = 0 if player.global_position.x > global_position.x else 180
	if is_instance_valid(player) and state == "chase":
		var target_pos = player.global_position
		target_pos.y = global_position.y
		nav.target_position = target_pos
		var next_pos = nav.get_next_path_position()
		next_pos.y = global_position.y
		velocity = (next_pos - global_position).normalized() * speed
	else:
		velocity = Vector3.ZERO

	move_and_slide()

func _update_idle() -> void:
	if state_locked:
		return
	state_locked = true
	var dir = (player.global_position - global_position).normalized()
	velocity = Vector3.ZERO
	if player.global_position.x > global_position.x:
		sprite.rotation_degrees.y = 0
	else:
		sprite.rotation_degrees.y = 180
	var player_dir = get_player_direction()
	match player_dir:
		"up":
			sprite.play("love_up")
		"down":
			sprite.play("love_down")
		"right", "up_right", "down_right":
			sprite.play("love_right")
	await get_tree().create_timer(3).timeout
	state_locked = false
	pick_next_state()

func _update_chase() -> void:
	if state_locked:
		return
	state_locked = true
	if nav.is_navigation_finished():
		nav.target_position = player.global_position
	var rand_wait = randi_range(3,5)
	await get_tree().create_timer(rand_wait).timeout
	state_locked = false
	pick_next_state()

func pick_next_state() -> void:
	if state_locked:
		return
	$spike_area/CollisionShape3D.disabled = true
	if not enraged:
		if randf() < 0.5:
			state = "idle"
		else:
			state = "chase"
	elif enraged:
		if (state == "chase" or state == "idle"):
			if randf() < 0.5:
				state = "attack"
			else:
				if randf() < 0.5:
					state = "spike"
				else:
					state = "idle"

		elif (state == "attack" or state == "spike"):
			if randf() < 0.5:
				state = "idle"
			else:
				state = "chase"

func spike() -> void:
	if state_locked:
		return
	state_locked = true
	sprite.play("spike")
	await get_tree().create_timer(0.5).timeout
	spike_area.disabled = false
	await get_tree().create_timer(1.25).timeout
	spike_area.disabled = true
	state_locked = false
	pick_next_state()

func shoot() -> void:
	if state_locked:
		return
	state_locked = true

	var shoot_dir = (player.global_position - global_position).normalized()
	velocity = Vector3.ZERO
	await get_tree().create_timer(0.3).timeout

	var player_dir = get_player_direction()
	match player_dir:
		"up":
			sprite.play("attack_up")
		"down":
			sprite.play("attack_down")
		"right", "up_right", "down_right":
			sprite.play("attack_right")

	await get_tree().create_timer(0.5).timeout
	var slime_ball = preload("res://Assets/Scenes/slime_ball.tscn")
	var slime_ball_scene = slime_ball.instantiate()
	get_parent().add_child(slime_ball_scene)
	slime_ball_scene.global_position = global_position
	slime_ball_scene.get_child(0).play(str(colour))

	await get_tree().create_timer(1).timeout

	state_locked = false
	pick_next_state()

func _on_hitbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player-Hitbox"):
		health -= Global.player_dmg
		DamageNumbers.display_number(Global.player_dmg, damage_numbers_origin.global_position)
	elif area.is_in_group("Slam_Box"):
		health -= Global.player_dmg - 3
		DamageNumbers.display_number(Global.player_dmg-3, damage_numbers_origin.global_position)

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	if state == "chase":
		velocity = velocity.move_toward(safe_velocity * speed, 0.7)
	move_and_slide()

func _on_area_area_entered(area: Area3D) -> void:
	$healed.play()
	var heal_amount = 10
	var new_health = health + heal_amount
	if new_health > $Health_bar_viewport/health_bar.max_value:
		$Health_bar_viewport/health_bar.max_value = new_health
	health = new_health
	$Health_bar_viewport/health_bar.value = health
	DamageNumbers.display_heal_number(10, damage_numbers_origin.global_position)
	sprite.modulate = "78ffaa"
	await get_tree().create_timer(0.25).timeout
	sprite.modulate = "ffffff"

func get_player_direction() -> String:
	var dir = (player.global_position - global_position).normalized()
	var tolerance = 0.3

	if abs(dir.x) > abs(dir.z):
		return "right"
	else:
		if dir.z < -tolerance:
			return "up"
		elif dir.z > tolerance:
			return "down"
		else:
			return "down"
