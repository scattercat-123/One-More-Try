extends Camera3D
var once = true
@export var shake_intensity := 0.2
@export var shake_duration := 0.5
@export var shake_speed := 30.0
var shaking := false
var shake_timer := 0.0

func _process(delta: float) -> void:
	if $"../AnimationPlayer".current_animation == "storm_see" and once:
		once = false
		await get_tree().create_timer(1.8).timeout
		$"../Storm_scene/lightning_tree".play("default")
		$"../Storm_scene".play_lightning_sound()
		var tree: MeshInstance3D = $"../NavigationRegion3D/Objects/tree1/Cylinder_019"
		var tree_material = tree.mesh.surface_get_material(0)
		var current_albedo = tree_material.albedo_color
		var darkened_albedo = current_albedo * 0.5
		tree_material.albedo_color = darkened_albedo
		var tree2: MeshInstance3D = $"../NavigationRegion3D/Objects/tree1/Sphere_014"
		var tree2_material = tree2.mesh.surface_get_material(0)
		var current_albedoo = tree2_material.albedo_color
		var darkened_albedoo = current_albedoo * 0.5
		tree2_material.albedo_color = darkened_albedoo
	if shaking:
		shake_timer -= delta
		if shake_timer > 0:
			position = position + Vector3(
				(randf() - 0.5) * 2.0 * shake_intensity,
				(randf() - 0.5) * 2.0 * shake_intensity,
				(randf() - 0.5) * 2.0 * shake_intensity
			)
		else:
			shaking = false
		
func start_earthquake(intensity := 0.2, duration := 0.5):
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
	shaking = true
