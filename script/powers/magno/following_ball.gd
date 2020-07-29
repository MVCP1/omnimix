extends Area


var speed = 1
var damage
var dad
var team = "N"

var target

var track_distance = 100

var stop

# Called when the node enters the scene tree for the first time.
func _ready():
	$RayCast.cast_to = Vector3(0,0,-speed)
	$front.translation = Vector3(0,0,-speed)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass

func _physics_process(delta):
	#Move the bullet forwards
	$RayCast.force_raycast_update()
	if $RayCast.is_colliding():
		hit($RayCast.get_collider())
	else:
		if target != null:
			if global_transform.origin.distance_to(target.global_transform.origin) > track_distance:
				target = null
			else:
				look_at(target.global_transform.origin, Vector3(0,1,0))
		global_translate(($front.global_transform.origin) - global_transform.origin)
	pass


func _on_bullet_body_entered(body):
	hit(body)
	pass # Replace with function body.


func hit(it):
	if it.name != dad:
		if it.is_in_group("player"):
			if team != it.team:
				if (get_tree().is_network_server()):
					it.rpc("damage", damage)
		var eclass = load("res://particles/explosion.tscn")
		var eactor = eclass.instance()
		eactor.global_translate(global_transform.origin)
		get_parent().add_child(eactor)
		queue_free()
	pass


func _on_Area_body_entered(body):
	if target == null:
		if body.is_in_group("player"):
			if team != body.team:
				target = body
	pass # Replace with function body.
