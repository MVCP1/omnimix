extends CanvasLayer


var choice = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_confirm_button_down():
	if choice != "":
		get_parent().rpc("add_powers", choice)
		queue_free()
	pass # Replace with function body.



func _on_blank_button_down():
	choice = "blank"
	pass # Replace with function body.


func _on_traveller_button_down():
	choice = "traveller"
	pass # Replace with function body.


func _on_kinematic_button_down():
	choice = "kinematic"
	pass # Replace with function body.


