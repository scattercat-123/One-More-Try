extends CharacterBody3D

@onready var sprite: AnimatedSprite3D = $sprite
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var damage_numbers_origin: Node3D = $Damage_Numbers_Origin
@onready var damage_jump: CollisionShape3D = $Damage_Jump/CollisionShape3D
@onready var damage_attack: CollisionShape3D = $Damage_Attack/CollisionShape3D
@onready var jump_path: MeshInstance3D = $Jump_Path
@onready var label: Label3D = $Label3D
@export var speed: float = 1.25
@export var max_health: int = 500
var health: int = max_health
var player
var state: String = "idle"
var state_timer: float = 0.0
const STATE_LENGTH := 4.0
var state_locked := false
var no_hand := false
var hand_grow_timer := 0.0
const HAND_GROW_DELAY := 6.0
const HAND_GROW_THRESHOLD := 150
var playing_hand_grow := false

var did_attack := false
var did_jump := false
var is_slamming := false
var is_attacking := false
var timer_for_showing_path := 1.5

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	state = "chase"
	jump_path.visible = false
	state_timer = 0.0
	damage_jump.disabled = true
	damage_attack.disabled = true

func _process(delta: float) -> void:
	state_timer += delta
	if state == "rush_attack":
		speed = 1.75
	if not state_locked and state_timer >= STATE_LENGTH:
		pick_next_state()
	if state == "idle":
		_update_idle()
	elif state == "chase":
		_update_chase()
	elif state == "rush_attack":
		attack()
	elif state == "slam":
		jumpy()
	label.text = state
	if health <= 0:
		Global.enemies_left -= 1
		get_tree().change_scene_to_file("res://Assets/Scenes/game_done.tscn")
		queue_free()
		return
	if health <= max_health - HAND_GROW_THRESHOLD and not no_hand:
		no_hand = true
		hand_grow_timer = 0.0
		max_health -= HAND_GROW_THRESHOLD
	if no_hand and not playing_hand_grow:
		hand_grow_timer += delta
		if hand_grow_timer >= HAND_GROW_DELAY:
			hand_grow_timer = 0.0
			play_hand_grow()

func _physics_process(delta: float) -> void:
	# gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	if not playing_hand_grow:
		if velocity.length() > 0.01 and not (is_slamming or is_attacking):
			if no_hand:
				sprite.play("no_hand_run")
			else:
				sprite.play("run")
		if is_instance_valid(player):
			sprite.rotation_degrees.y = 180 if player.global_position.x > global_position.x else 0
	move_and_slide()
	if is_instance_valid(player):
		var target_pos = player.global_position
		target_pos.y = global_position.y
		nav.target_position = target_pos
		var next_pos = nav.get_next_path_position()
		next_pos.y = global_position.y
		velocity = (next_pos - global_position).normalized() * speed

func _update_idle() -> void:
	velocity = Vector3.ZERO
	if playing_hand_grow:
		return
	if no_hand:
		sprite.play("no_hand_idle")
	else:
		sprite.play("idle")

func _update_chase() -> void:
	if nav.is_navigation_finished():
		nav.target_position = player.global_position

func play_hand_grow() -> void:
	if playing_hand_grow:
		return
	playing_hand_grow = true
	state_locked = true
	no_hand = false
	sprite.play("hand_grow")
	await sprite.animation_finished
	playing_hand_grow = false
	state_locked = false
	if velocity.length() > 0.01:
		sprite.play("run")
	else:
		sprite.play("idle")

func pick_next_state() -> void:
	if state_locked:
		return
	jump_path.visible = false
	damage_jump.disabled = true
	damage_attack.disabled = true

	if state == "chase":
		if not no_hand:
			if randf() < 0.5:
				state = "rush_attack"
			else:
				state = "slam"
		else:
			if randf() < 0.5:
				state = "idle"
			else:
				state = "chase"
	elif state == "rush_attack" or state == "slam":
		if randf() < 0.5:
			state = "idle"
		else:
			state = "chase"
	elif state == "idle":
		state = "chase"

	state_timer = 0.0

func jumpy() -> void:
	if state_locked or did_jump:
		return
	is_slamming = true
	did_jump = true
	state_locked = true
	jump_path.visible = true
	await get_tree().create_timer(timer_for_showing_path).timeout
	sprite.play("slam")
	damage_jump.disabled = false
	await get_tree().create_timer(2.25).timeout
	damage_jump.disabled = true
	jump_path.visible = false
	state_locked = false
	is_slamming = false
	did_jump = false
	pick_next_state()

func attack() -> void:
	if state_locked or did_attack:
		return
	is_attacking = true
	did_attack = true
	state_locked = true

	sprite.play("rush_attack")
	damage_attack.disabled = false
	await get_tree().create_timer(3).timeout
	damage_attack.disabled = true

	state_locked = false
	is_attacking = false
	did_attack = false
	pick_next_state()

func _on_hitbox_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player-Hitbox"):
		health -= Global.player_dmg
		DamageNumbers.display_number(Global.player_dmg, damage_numbers_origin.global_position)
	elif area.is_in_group("Slam_Box"):
		health -= max(0, Global.player_dmg - 3)
		DamageNumbers.display_number(Global.player_dmg, damage_numbers_origin.global_position)

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	if state == "chase":
		velocity = velocity.move_toward(safe_velocity * speed, 0.7)
	move_and_slide()
