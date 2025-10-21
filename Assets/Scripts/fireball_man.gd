extends CharacterBody3D
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
var can_move=false
var enabled = true
var facing: String
@onready var nav: NavigationAgent3D = $NavigationAgent3D
var flip_speed = 20
@export var speed := 1
var health = 40
var once = false
var player
var start = false
@onready var damage_numbers_origin: Node3D = $Damage_Numbers_Origin
@onready var debug_label: Label3D = $debug_label_2
var can_shoot = true
var state := "idle"
var state_timer := 0.0
const STATE_LENGTH := 3.0
@onready var pivot_hit_path: Node3D = $Pivot_Hit_path
var _pivot_aimed := false
var _is_firing := false

var state_weights := {
	"chase": 0.40,
	"fireball": 0.35,
	"idle": 0.25
}

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	Dialogic.signal_event.connect(signaling)
	state = "chase"
	state_timer = 0.0
	if Global.debug_mode == false:
		debug_label.visible = false
	var rand_spawm_sound = randf_range(0.0, 3.5)
	if Global.wave > 1:
		await get_tree().create_timer(rand_spawm_sound).timeout
		$SFX/spawn.play()

func _process(delta: float) -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player < 4 :
		state_weights = {
			"chase": 0.3,
			"fireball": 0.45,
			"idle": 0.25
		}
	else:
		state_weights = {
			"chase": 0.40,
			"fireball": 0.35,
			"idle": 0.25
		}
	debug_label.text = str(health)
	if can_move or Global.debug_mode == true or not Global.wave == 1:
		rotation_degrees.y = 0
		if start or not Global.wave == 1 and Global.player_health > 0:
			state_timer += delta
			if state_timer >= STATE_LENGTH:
				pick_next_state()
			match state:
				"idle":
					_update_idle(delta)
				"chase":
					_update_chase(delta)
				"fireball":
					fireball_shoot()
	else:
		rotation_degrees.y = 90
	if health <= 0 or global_position.y <= -1:
		visible = false
		if Global.wave > 1:
			get_tree().call_group("Spawner", "on_enemy_died")
		queue_free()
		Global.enemies_left = Global.enemies_left - 1
func _physics_process(delta: float) -> void:
	if state == "chase":
		var direction = velocity.normalized()
		if direction.x > 0:
			sprite.rotation_degrees.y = shortest_angle_deg(sprite.rotation_degrees.y, 0, flip_speed)
		else:
			sprite.rotation_degrees.y = shortest_angle_deg(sprite.rotation_degrees.y, 180, flip_speed)

	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if velocity.normalized().length() > 0.01:
		playwalk(velocity.normalized())

	move_and_slide()
	
func signaling(arg):
	if arg == "fight_first_enemy":
		can_move = true
	if arg == "start_attack":
		start = true

func navigator(_delta):
	var target_pos = player.global_position
	target_pos.y = global_position.y
	nav.target_position = target_pos
	var next_pos = nav.get_next_path_position()
	next_pos.y = global_position.y
	var direction = (next_pos - global_position).normalized()
	velocity = direction * speed

func playwalk(dir: Vector3) -> void: #RUNNING logic
	var tolerance = 0.3

	var dx = dir.x
	var dz = dir.z
	if abs(dx) < tolerance:
		dx = 0
	if abs(dz) < tolerance:
		dz = 0

	if dz < 0 and abs(dx) > 0:
		sprite.play("up_left_right_run")
		facing = "up_right"
	elif dz > 0 and abs(dx) > 0:
		sprite.play("down_left_right_run")
		facing = "down_right"
	elif abs(dx) > 0 and dz == 0:
		sprite.play("right_left_run")
		facing = "right"
	elif dz < 0:
		facing = "up"
		sprite.play("up_run")
	elif dz > 0:
		facing = "down"
		sprite.play("down_run")

func shortest_angle_deg(current: float, target: float, step: float) -> float:
	var diff = fmod((target - current + 180), 360) - 180
	return current + clamp(diff, -step, step)

func _on_hitbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player-Hitbox"):
		if not player:
			return
		var dir_to_enemy = (global_position - player.global_position).normalized()

		var facing_dir = player.last_dir.normalized()

		var angle = rad_to_deg(facing_dir.angle_to(dir_to_enemy))

		if angle < 80:
			health -= Global.player_dmg
			DamageNumbers.display_number(Global.player_dmg, damage_numbers_origin.global_position, )
	if area.is_in_group("Slam_Box"):
			health -= (Global.player_dmg) - 3
			DamageNumbers.display_number(Global.player_dmg, damage_numbers_origin.global_position, )
func pick_next_state() -> void:
	var roll = randf()
	var acc = 0.0
	for s in state_weights.keys():
		acc += state_weights[s]
		if roll <= acc:
			state = s
			state_timer = 0.0
			_pivot_aimed = false
			_is_firing = false
			return
	state = "idle"
	state_timer = 0.0
	_pivot_aimed = false
	_is_firing = false

func _update_chase(delta: float) -> void:
	navigator(delta)
	velocity = velocity.normalized() * speed
	
func _update_idle(_delta: float) -> void:
	velocity = Vector3.ZERO
	var player_dir = get_player_direction()
	if player.global_position.x > global_position.x:
		sprite.rotation_degrees.y = 0
	else:
		sprite.rotation_degrees.y = 180
	match player_dir:
		"up":
			sprite.play("up_idle")
		"down":
			sprite.play("down_idle")
		"right":
			sprite.play("right_left_idle")
		"up_right":
			sprite.play("up_right_left_idle")
		"down_right":
			sprite.play("down_right_left_idle")

func fireball_shoot() -> void:
	var shoot_dir = (player.global_position - global_position).normalized()
	if not _pivot_aimed:
		_pivot_aimed = true
		pivot_hit_path.global_position = global_position
		pivot_hit_path.look_at(player.global_position, Vector3.UP)
		pivot_hit_path.rotate_y(deg_to_rad(90))
		pivot_hit_path.visible = true

	if _is_firing or not can_shoot:
		return

	_is_firing = true
	can_shoot = false
	velocity = Vector3.ZERO
	await get_tree().create_timer(0.3).timeout

	var player_dir = get_player_direction()
	match player_dir:
		"up":
			sprite.play("up_shoot")
		"down":
			sprite.play("down_shoot")
		"right":
			sprite.play("right_left_shoot")
		"up_right":
			sprite.play("up_left_right_shoot")
		"down_right":
			sprite.play("down_right_left_shoot")

	await get_tree().create_timer(0.3).timeout
	$SFX/fireball.play()
	var fireball_scene = preload("res://Assets/Scenes/fireball.tscn")
	var fireball = fireball_scene.instantiate()
	get_parent().add_child(fireball)

	fireball.global_position = global_position
	fireball.direction = shoot_dir

	await get_tree().create_timer(0.5).timeout
	pick_next_state()
	state_timer = 0
	_is_firing = false
	can_shoot = true
	pick_next_state()
	state_timer = 0.0
	pivot_hit_path.visible = false
	_pivot_aimed = false
	
func get_player_direction() -> String:
	var dir = (player.global_position - global_position).normalized()
	var tolerance = 0.4

	if abs(dir.x) < tolerance:
		dir.x = 0
	if abs(dir.z) < tolerance:
		dir.z = 0

	if dir.z < 0 and abs(dir.x) > 0:
		return "up_right"
	elif dir.z > 0 and abs(dir.x) > 0:
		return "down_right"
	elif abs(dir.x) > 0 and dir.z == 0:
		return "right"
	elif dir.z < 0:
		return "up"
	elif dir.z > 0:
		return "down"
	return "down"


func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	if state == "chase" and can_move:
		velocity = velocity.move_toward(safe_velocity * speed, 0.7)
		move_and_slide()

func _on_area_area_entered(area: Area3D) -> void:
	health += 10
	DamageNumbers.display_heal_number(10, damage_numbers_origin.global_position)
