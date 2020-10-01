extends Spatial


var dad
var team = "N"


# Called when the node enters the scene tree for the first time.
func _process(delta):
	#TEAM COLLISION
	$StaticBody.set_collision_layer_bit(1, team == "A")
	$StaticBody.set_collision_layer_bit(2, team == "B")
	
	#TEAM COLOR
	$StaticBody/MeshInstance.set_surface_material(0, $StaticBody/MeshInstance.get_surface_material(0).duplicate())
	if get_tree().current_scene.get_node(str(gamestate.player_info.net_id)).team != team:
		$StaticBody/MeshInstance.get_surface_material(0).albedo_color = Color(1, 0, 0, 0.3)
	else:
		$StaticBody/MeshInstance.get_surface_material(0).albedo_color = Color(0, 0, 1, 0.3)
	pass # Replace with function body.


func _on_Timer_timeout():
	queue_free()
	pass # Replace with function body.
