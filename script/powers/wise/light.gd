extends Spatial


# Declare member variables here. Examples:
var dad
var team = "N"

var target
var time

var angle = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	$Timer.wait_time = time
	get_tree().current_scene.get_node(target).rpc("see", time)
	$Timer.start()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_transform.origin = get_tree().current_scene.get_node(target).global_transform.origin
	$MeshInstance.translation = Vector3(cos(angle)*0.5, 1, sin(angle)*0.5)
	angle += delta*10
	pass


func _on_Timer_timeout():
	queue_free()
	pass # Replace with function body.
