extends CharacterBody3D

@onready var nav: NavigationAgent3D = $NavigationAgent3D
var target: Node3D = null
@export var speed: float = 4.0

func _ready():
	await get_tree().process_frame
	find_target()
	$glow.play()
	
func _process(delta):
	if not is_instance_valid(target):
		find_target()
		return
	nav.target_position = target.global_position
	if nav.is_navigation_finished():
		return
	var next_pos = nav.get_next_path_position()
	var dir = (next_pos - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
func find_target():
	var enemies = get_tree().get_nodes_in_group("Enemies")
	if enemies.size() > 0:
		target = enemies.pick_random()
		nav.target_position = target.global_position
	
func _on_hit_area_entered(area: Area3D) -> void:
		$healed.play()
		queue_free()
		pass
