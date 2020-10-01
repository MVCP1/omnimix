extends RigidBody


var speed = 1
var damage
var dad
var team = "N"

var stun_time = 1.0

var impulse = 20
var height = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	apply_central_impulse(($front.global_transform.origin - global_transform.origin)*impulse + Vector3(0,height,0))
	pass # Replace with function body.

func _physics_process(delta):
	$Area.set_collision_mask_bit(1, team == "B")
	$Area.set_collision_mask_bit(2, team == "A")
	pass

func _on_Area_body_entered(body):
	hit(body)
	pass # Replace with function body.


func hit(it):
	if it.name != dad:
		if it.is_in_group("player"):
			if team != it.team:
				if (get_tree().is_network_server()):
					it.rpc("damage", damage)
					it.rpc("stun", stun_time)
		var eclass = load("res://particles/explosion.tscn")
		var eactor = eclass.instance()
		eactor.global_translate(global_transform.origin)
		get_parent().add_child(eactor)
		queue_free()
	pass
