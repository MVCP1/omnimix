extends Spatial


puppetsync var percentA = 0
puppetsync var percentB = 0

var hasA = false
var hasB = false
puppetsync var team = "N"

puppetsync var cap = 0
puppetsync var capturing = false
puppetsync var contesting = false

puppetsync var won = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(delta):
	if not won:
		if (get_tree().is_network_server()):
			contesting = hasA and hasB
			
			hasA = false
			hasB = false
			for i in $Area.get_overlapping_bodies():
				if i.is_in_group("player"):
					if i.is_in_group("teamA"):
						hasA = true
					if i.is_in_group("teamB"):
						hasB = true
			
			if not (hasA and hasB) and (hasA or hasB):
				if hasA:
					if team == "B" and cap < 100:
						capturing = true
					else:
						team = "A"
						capturing = false
						if cap >= 100:
							cap = 0
				if hasB:
					if team == "A" and cap < 100:
						capturing = true
					else:
						team = "B"
						capturing = false
						if cap >= 100:
							cap = 0
			if not (hasA or hasB):
				capturing = false
		
		if (get_tree().is_network_server()):
			rset("contesting", contesting)
			rset("capturing", capturing)
			rset("cap", cap)
			rset("team", team)
		$CanvasLayer/Panel/Contesting.visible = contesting
		$CanvasLayer/Panel/Capturing.visible = capturing and not contesting
		$CanvasLayer/Panel/ProgressBar.value = cap
		$CanvasLayer/Panel/ProgressBar.visible = (cap > 0) or capturing
		
		$CanvasLayer/Panel/A/A.text = str(percentA/10.0) + "%"
		$CanvasLayer/Panel/B/B.text = str(percentB/10.0) + "%"
		
		if team == "A":
			$Step/Light.material.albedo_color = Color(0,0,1)
			$Step/Light.material.emission = Color(0,0,1)
		if team == "B":
			$Step/Light.material.albedo_color = Color(1,0,0)
			$Step/Light.material.emission = Color(1,0,0)
	pass


func _on_Timer_timeout():
	if not won:
		if (get_tree().is_network_server()):
			if capturing and not contesting:
				cap += 10
			if not capturing and not contesting and cap > 0:
				cap -= 10
			if not((cap > 0 or contesting) and ((team == "A") and (percentA + 100 >= 1000) or (team == "B") and (percentB + 100 >= 1000))):
				if team == "A":
					percentA = percentA + 100
				if team == "B":
					percentB = percentB + 100
		if (get_tree().is_network_server()):
			rset("percentA", percentA)
			rset("percentB", percentB)
		
		if percentA >= 1000 or percentB >= 1000:
			if (get_tree().is_network_server()):
				rset("won", true)
				rpc("winning")
	pass # Replace with function body.
	
remotesync func winning():
	$CanvasLayer/Panel/Contesting.visible = false
	$CanvasLayer/Panel/Capturing.visible = false
	$CanvasLayer/Panel/ProgressBar.visible = false
		
	$CanvasLayer/Panel/A/A.text = str(percentA/10.0) + "%"
	$CanvasLayer/Panel/B/B.text = str(percentB/10.0) + "%"
	
	$CanvasLayer/Won/Winner.text = team
	$CanvasLayer/Won.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	pass
