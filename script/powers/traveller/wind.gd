extends Area


# Declare member variables here. Examples:
var dad
var team = "N"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for i in get_overlapping_bodies():
		if i.is_in_group("player"):
			i.rpc("add_knockback", Vector3(0,1,0))
			#i.y_vel = i.JUMP_FORCE
	pass


func _on_Timer_timeout():
	queue_free()
	pass # Replace with function body.
