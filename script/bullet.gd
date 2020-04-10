extends Area


var speed  = 30.0
var damage  = 1
var dad
var front : Vector3

var repl_position = Transform()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#Move the bullet forwards
	global_translate(front * speed * delta)
	pass


func _on_bullet_body_entered(body):
	if body.name != dad:
		if body.is_in_group("player"):
			if (get_tree().is_network_server()):
				body.rpc("damage", 10)
		var eclass = load("res://scenes/explosion.tscn")
		var eactor = eclass.instance()
		eactor.global_translate(global_transform.origin)
		get_parent().add_child(eactor)
		queue_free()
	pass # Replace with function body.
