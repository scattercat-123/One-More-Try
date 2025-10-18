extends CharacterBody3D
@onready var sprite: AnimatedSprite3D = $sprite
var enabled = true
var facing: String
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@export var speed := 1.5
var health = 1250
var max_health = 1250
var no_hand = false
var hand_grow_timer = 0.0
const HAND_GROW_DELAY = 6.0
var once = false
var player
@onready var damage_numbers_origin: Node3D = $Damage_Numbers_Origin
@onready var debug_label: Label3D = $Label3D
var can_shoot = true
var state := "idle"
var state_timer := 0.0
const STATE_LENGTH := 4.0
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

func _ready() -> void:
	Dialogic.signal_event.connect(signaling)
	attack_path.visible = false
	jump_path.visible = false
	player = get_tree().get_first_node_in_group("Player")
	state = "chase"
	state_timer = 0.0

func _process(delta: float) -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	state_timer += delta
	if not state_locked and state_timer >= STATE_LENGTH:
		pick_next_state()
	match state:
		"idle":
			_update_idle()
		"chase":
			_update_chase(delta)
		"rush_attack":
			attack()
		"slam":
			jumpy()
	if health <= 0:
		visible = false
		queue_free()
		Global.enemies_left = Global.enemies_left - 1
	if health <= max_health - 20 and not no_hand:
		no_hand = true
		hand_grow_timer = 0.0

	if no_hand:
		hand_grow_timer += delta
		if hand_grow_timer >= HAND_GROW_DELAY:
			no_hand = false
			sprite.play("hand_grow")
		await sprite.animation_finished

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if velocity.normalized().length() > 0.01:
		playwalk()
	if player.global_position.x > global_position.x:
		sprite.rotation_degrees.y = 180
	else:
		sprite.rotation_degrees.y = 0
	move_and_slide()
	var target_pos = player.global_position
	target_pos.y = global_position.y
	nav.target_position = target_pos
	var next_pos = nav.get_next_path_position()
	next_pos.y = global_position.y
	var direction = (next_pos - global_position).normalized()
	velocity = direction * speed

func signaling(arg):
	pass

func playwalk() -> void:
	if no_hand:
		sprite.play("no_hand_run")
	else:
		sprite.play("run")

func _update_idle() -> void:
	velocity = Vector3.ZERO
	if no_hand:
		sprite.play("mini_idle")
	else:
		sprite.play("idle")

func _on_hitbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player-Hitbox"):
		var dir_to_enemy = (global_position - player.global_position).normalized()
		var facing_dir = player.last_dir.normalized()
		var angle = rad_to_deg(facing_dir.angle_to(dir_to_enemy))
		if angle < 80:
			health -= Global.player_dmg
			DamageNumbers.display_number(Global.player_dmg, damage_numbers_origin.global_position)
	if area.is_in_group("Slam_Box"):
			health -= (Global.player_dmg) - 3
			DamageNumbers.display_number(Global.player_dmg, damage_numbers_origin.global_position)

func pick_next_state() -> void:
	if state_locked:
		return

	_pivot_aimed = false
	jump_path.visible = false
	damage_jump.disabled = true
	damage_attack.disabled = true
	attack_path.visible = false

	match state:
		"chase":
			# after chasing → choose between attack or slam
			if randf() < 0.5:
				state = "rush_attack"
			else:
				state = "slam"

		"rush_attack", "slam":
			# after attack/slam → decide idle or chase again
			if randf() < 0.3:
				state = "idle"
			else:
				state = "chase"

		"idle":
			# after idle → always go back to chase
			state = "chase"

		_:
			state = "chase"

	state_timer = 0.0
	_pivot_aimed = false
	_is_firing = false


func _update_chase(delta: float) -> void:
	if nav.is_navigation_finished():
		nav.target_position = player.global_position
		return
	# we don’t move here directly — only update nav target
	nav.target_position = player.global_position

func jumpy() -> void:
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
	sprite.play("slam")
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
	sprite.play("rush_attack")
	if abs(dx) < tolerance:
		dx = 0
	if abs(dz) < tolerance:
		dz = 0
	if player.global_position.x > global_position.x:
		sprite.rotation_degrees.y = 0
	else:
		sprite.rotation_degrees.y = 180
	sprite.play()
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

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	if state == "chase":
		velocity = velocity.move_toward(safe_velocity * speed, 0.7)
	move_and_slide()
