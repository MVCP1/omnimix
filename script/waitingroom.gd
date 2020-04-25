extends Spatial

var teamA = [null]
var teamB = [null]

puppetsync var ready = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

#PRESSING ENTER TO START MATCH WHEN PLAYERS ARE READY
func _input(event):
	if (get_tree().is_network_server()):
		if Input.is_action_just_pressed("enter") and not ready:
			var readyA = true
			var readyB = true
			for i in teamA:
				readyA = (i != null) and readyA
			for i in teamB:
				readyB = (i != null) and readyB
			if readyA and not readyB:
				rset("ready", true)
				rpc("gates")

#CLOSING GATES AND STARTING COUNTDOWN
remotesync func gates():
	get_node("Gates").translation = Vector3(0,0,0)
	get_node("Timer").start()
	$Countdown.play(26.0)

#MOVING PLAYERS AFTER COUNTDOWN
func _on_Timer_timeout():
	$Countdown.stop()
	$Begin.play()
	for i in teamA:
		i.global_transform.origin = Vector3(0,0,0)
	#for i in teamB:
		#i.global_transform.origin = Vector3(0,0,0)
	pass # Replace with function body.


#TEAM A READY POINTS

func _on_A1_body_entered(body):
	if teamA[0] == null and ready == false:
		if body.is_in_group("player"):
			teamA[0] = body
			$TeamA/Spot1/SpotLight.light_color = Color(0,1,0)
	pass # Replace with function body.
func _on_A1_body_exited(body):
	if teamA[0] != null and ready == false:
		if body == teamA[0]:
			teamA[0] = null
			$TeamA/Spot1/SpotLight.light_color = Color(1,0,0)
	pass # Replace with function body.



#TEAM B READY POINTS

func _on_B1_body_entered(body):
	if teamB[0] == null and ready == false:
		if body.is_in_group("player"):
			teamB[0] = body
			$TeamB/Spot1/SpotLight.light_color = Color(0,1,0)
	pass # Replace with function body.
func _on_B1_body_exited(body):
	if teamB[0] != null and ready == false:
		if body == teamB[0]:
			teamB[0] = null
			$TeamB/Spot1/SpotLight.light_color = Color(1,0,0)
	pass # Replace with function body.
