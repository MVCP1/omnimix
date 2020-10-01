extends RigidBody


var speed = 1

var damage
var bonus

var dad
var team = "N"

var impulse = 20
var height = 5

var rgb

# Called when the node enters the scene tree for the first time.
func _ready():
	$CollisionShape/MeshInstance.set_surface_material(0, $CollisionShape/MeshInstance.get_surface_material(0).duplicate())
	$CollisionShape/MeshInstance.get_surface_material(0).albedo_color = Color(rgb.x, rgb.y, rgb.z, 1)
	$CollisionShape/MeshInstance.get_surface_material(0).emission = Color(rgb.x, rgb.y, rgb.z, 1)
	apply_central_impulse(($front.global_transform.origin - global_transform.origin)*impulse + Vector3(0,height,0))
	pass # Replace with function body.


func _physics_process(delta):
	set_collision_mask_bit(1, team == "B")
	set_collision_mask_bit(2, team == "A")
	$Hit.set_collision_mask_bit(1, team == "B")
	$Hit.set_collision_mask_bit(2, team == "A")
	pass


func _on_Hit_body_entered(body):
	if body.name != dad and body.name != name:
		for it in get_node("Area").get_overlapping_bodies():
			if it.is_in_group("player"):
				if it.name != dad:
					if (is_network_master()):
						if rgb.x == 1:
							if team != it.team:
								it.rpc("damage", damage*bonus)
						if team == it.team:
							if rgb.y == 1:
								it.rpc("heal", damage)
							if rgb.z == 1:
								it.rpc("power_up", damage)
		var eclass = load("res://particles/explosion.tscn")
		var eactor = eclass.instance()
		eactor.global_translate(global_transform.origin)
		get_parent().add_child(eactor)
		queue_free()
	pass # Replace with function body.
