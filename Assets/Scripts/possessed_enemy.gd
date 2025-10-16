extends CharacterBody3D
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
var enabled = true
var facing: String
@onready var nav: NavigationAgent3D = $NavigationAgent3D
var flip_speed = 20
@export var speed := 1
var health = 70
var once = false
var player
var is_flip = false
var can_move = false
@onready var damage_numbers_origin: Node3D = $Damage_Numbers_Origin
@onready var debug_label: Label3D = $Label3D
var can_shoot = true
var state := "idle"
var state_timer := 0.0
const STATE_LENGTH := 3.0
@onready var debug_label_2: Label3D = $debug_label_2
var _pivot_aimed := false
var _is_firing := false
@onready var jump_path: MeshInstance3D = $Jump_Path
var timer_for_showing_path = 1.2
@onready var damage_jump: CollisionShape3D = $Damage_Jump/CollisionShape3D
var state_locked = false
@onready var damage_attack: CollisionShape3D = $Damage_Attack/CollisionShape3D
@onready var attack_path: Node3D = $"Attack Path"
var did_attack = false
var did_jump = false

var state_weights := {
	"chase": 0.40,
	"attack": 0.0,
	"idle": 0.25,
	"jumpy": 0,
}

func _ready() -> void:
	Dialogic.signal_event.connect(signaling)
	attack_path.visible = false
	jump_path.visible = false
	player = get_tree().get_first_node_in_group("Player")
	state = "chase"
	state_timer = 0.0
	if Global.debug_mode == false:
		debug_label.visible = false

func _process(delta: float) -> void:
	if is_flip or Global.debug_mode or not Global.wave == 1:
		rotation_degrees.y = 0
		if can_move or not Global.wave == 1 and Global.player_health > 0:
			var distance_to_player = global_position.distance_to(player.global_position)
			if distance_to_player < 1 and not state_locked:
				state_weights = {
					"chase": 0.125,
					"attack": 0.375,
					"idle": 0.125,
					"jumpy": 0.375,
				}
			else:
				state_weights = {
					"chase": 0.45,
					"attack": 0.1,
					"idle": 0.3,
					"jumpy": 0.15,
			}
			if Input.is_action_just_pressed("click") and state == "idle":
				await get_tree().create_timer(0.25).timeout
				pick_next_state()
				state_timer = 0
			if distance_to_player < 0.3 and state == "chase":
				state_timer = 0
				var rand = randi_range(0,1)
				if rand == 0:
					state = "jumpy"
				else:
					state = "attack"
			debug_label_2.text = str(velocity.length())
			state_timer += delta
			if not state_locked and state_timer >= STATE_LENGTH:
				pick_next_state()
			match state:
				"idle":
					_update_idle()
					debug_label.text = "idle"
				"chase":
					debug_label.text = "chase"
					_update_chase(delta)
				"attack":
					debug_label.text = "attack"
					attack()
				"jumpy":
					debug_label.text = "jump"
					jumpy(velocity.normalized())
			if health <= 0 or global_position.y <= -1:
				visible = false
				Global.enemies_left = Global.enemies_left - 1
				queue_free()
	else:
		rotation_degrees.y = 90

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if velocity.normalized().length() > 0.01:
		playwalk(velocity.normalized())

	move_and_slide()

func navigator(_delta):
	var target_pos = player.global_position
	target_pos.y = global_position.y
	nav.target_position = target_pos
	var next_pos = nav.get_next_path_position()
	next_pos.y = global_position.y
	var direction = (next_pos - global_position).normalized()
	velocity = direction * speed

func signaling(arg):
	if arg == "fight_first_enemy":
		is_flip = true
	if arg == "start_attack":
		can_move = true
	if arg == "monster_saw":
		$growl.play()

func playwalk(dir: Vector3) -> void: #running
	var tolerance = 0.3
	var dx = dir.x
	var dz = dir.z
	
	if abs(dx) < tolerance:
		dx = 0
	if abs(dz) < tolerance:
		dz = 0
	
	if abs(dx) > 0:
		sprite.play("right_walk")
		if dx > 0:
			sprite.rotation_degrees.y = 0
		else:
			sprite.rotation_degrees.y = 180
	elif dz < 0:
		sprite.play("up_walk")
	elif dz > 0:
		sprite.play("down_walk")

func _on_hitbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player-Hitbox"):
		var dir_to_enemy = (global_position - player.global_position).normalized()
		var facing_dir = player.last_dir.normalized()
		var angle = rad_to_deg(facing_dir.angle_to(dir_to_enemy))
		if angle < 80:
			health -= Global.player_dmg
			DamageNumbers.display_number(Global.player_dmg, damage_numbers_origin.global_position, )

func pick_next_state() -> void:
	if state_locked: 
		return
	_pivot_aimed = false
	jump_path.visible = false
	damage_jump.disabled = true
	damage_attack.disabled = true
	attack_path.visible = false
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

func _update_idle() -> void:
	var dir = (player.global_position - global_position).normalized()
	velocity = Vector3.ZERO
	if player.global_position.x > global_position.x:
		sprite.rotation_degrees.y = 0
	else:
		sprite.rotation_degrees.y = 180
	var tolerance = 0.3
	var dx = dir.x
	var dz = dir.z
	if abs(dx) < tolerance:
		dx = 0
	if abs(dz) < tolerance:
		dz = 0
	if abs(dx) > 0:
		sprite.play("right_idle")
		if dx > 0:
			sprite.rotation_degrees.y = 0
		else:
			sprite.rotation_degrees.y = 180
	elif dz < 0:
		sprite.play("up_idle")
	elif dz > 0:
		sprite.play("down_idle")

func jumpy(dir: Vector3) -> void:
	if state_locked or did_jump:
		return
	did_jump = true
	state_locked = true
	jump_path.visible = true
	await get_tree().create_timer(timer_for_showing_path).timeout
	velocity = Vector3.ZERO
	if player.global_position.x > global_position.x:
		sprite.rotation_degrees.y = 0
	else:
		sprite.rotation_degrees.y = 180
	var tolerance = 0.3
	var dx = dir.x
	var dz = dir.z
	$thump.play()
	if abs(dx) < tolerance:
		dx = 0
	if abs(dz) < tolerance:
		dz = 0
	if abs(dx) > 0:
		sprite.play("right_jump")
		if dx < 0:
			sprite.rotation_degrees.y = 180
		else:
			sprite.rotation_degrees.y = 0
	elif dz < 0:
		sprite.play("up_jump")
	elif dz > 0:
		sprite.play("down_jump")
	else:
		sprite.play("down_jump")
	await get_tree().create_timer(0.3).timeout
	damage_jump.disabled = false
	await sprite.animation_finished
	damage_jump.disabled = false
	damage_jump.disabled = true
	await get_tree().create_timer(0.75).timeout
	jump_path.visible = false
	pick_next_state()
	state_locked = false
	did_jump = false
func attack() -> void:
	if state_locked or did_attack:
		return
	did_attack = true
	state_locked = true
	if not _pivot_aimed:
		_pivot_aimed = true
		attack_path.visible = true
		attack_path.global_position = global_position

		var aim_timer := get_tree().create_timer(timer_for_showing_path)
		while aim_timer.time_left > 0:
			if not is_instance_valid(player):
				break
			attack_path.look_at(player.global_position, Vector3.UP)
			attack_path.rotate_y(deg_to_rad(90))
			await get_tree().process_frame

	velocity = Vector3.ZERO

	var dir = (player.global_position - global_position).normalized()
	var tolerance = 0.3
	var dx = dir.x
	var dz = dir.z

	if abs(dx) < tolerance:
		dx = 0
	if abs(dz) < tolerance:
		dz = 0
	if player.global_position.x > global_position.x:
		sprite.rotation_degrees.y = 0
	else:
		sprite.rotation_degrees.y = 180
	$swing.play()
	if abs(dx) > abs(dz):
		sprite.play("right_attack")
		if dx < 0:
			sprite.rotation_degrees.y = 180
		else:
			sprite.rotation_degrees.y = 0
	elif dz < 0:
		sprite.play("up_attack")
	elif dz > 0:
		sprite.play("down_attack")
	else:
		sprite.play("down_attack")
	await get_tree().create_timer(0.2).timeout
	damage_attack.disabled = false
	await sprite.animation_finished
	await get_tree().create_timer(0.5).timeout
	pick_next_state()
	damage_attack.disabled = true
	attack_path.visible = false
	state_locked = false
	_pivot_aimed = false
	did_attack = false

func _on_sound_timer_timeout() -> void:
	$SoundTimer.start() 
	if is_flip:
		var randi = randi_range(0,5)
		if randi == 0:
			$growl.play()
		elif randi == 1:
			$growl2.play()
		elif randi == 2:
			$growl3.play()

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	if state == "chase" and can_move:
		velocity = velocity.move_toward(safe_velocity * speed, 0.7)
		move_and_slide()
