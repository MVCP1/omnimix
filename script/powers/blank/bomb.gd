extends RigidBody


var speed = 1
var damage
var dad
var team = "N"

var impulse = 20
var height = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	apply_central_impulse(($front.global_transform.origin - global_transform.origin)*impulse + Vector3(0,height,0))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

#func _physics_process(delta):
#	pass


func _on_Timer_timeout():
	for it in get_node("Area").get_overlapping_bodies():
		if it.is_in_group("player"):
			if (is_in_group("teamA") and it.is_in_group("teamB")) or (is_in_group("teamB") and it.is_in_group("teamA")):
				if (get_tree().is_network_server()):
					it.rpc("damage", damage)
	var eclass = load("res://particles/explosion.tscn")
	var eactor = eclass.instance()
	eactor.global_translate(global_transform.origin)
	get_parent().add_child(eactor)
	queue_free()
	pass # Replace with function body.
