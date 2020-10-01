extends Area


var speed = 0.5
var dad
var team = "N"

var distance
var back = false
var target = null

# Called when the node enters the scene tree for the first time.
func _ready():
	$RayCast.cast_to = Vector3(0,0,-speed)
	$front.translation = Vector3(0,0,-speed)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass

func _physics_process(delta):
	set_collision_mask_bit(1, team == "B")
	set_collision_mask_bit(2, team == "A")
	$RayCast.set_collision_mask_bit(1, team == "B")
	$RayCast.set_collision_mask_bit(2, team == "A")
	
	$Spatial.rotation = $Spatial.rotation + Vector3(0,0.2,0)
	
	#Move the bullet forwards
	$RayCast.force_raycast_update()
	if $RayCast.is_colliding():
		hit($RayCast.get_collider())
	if not back:
		global_translate(($front.global_transform.origin) - global_transform.origin)
		distance -= speed
		if distance <= 0 and target == null:
			back = true
		
	if back:
		if target != null:
			target.global_transform.origin = global_transform.origin
		look_at(get_parent().get_node(dad).global_transform.origin, Vector3(0,1,0))
		global_translate(($front.global_transform.origin) - global_transform.origin)
		if global_transform.origin.distance_to(get_parent().get_node(dad).global_transform.origin) < 3:
			queue_free()
	pass


func _on_bullet_body_entered(body):
	hit(body)
	pass # Replace with function body.


func hit(it):
	if target == null:
		if it.name != dad:
			if it.is_in_group("player"):
				if team != it.team:
					global_transform.origin = it.global_transform.origin
					target = it
					back = true
			else:
				back = true
	else:
		if not it.is_in_group("player"):
			queue_free()
	pass
