extends Spatial


var percentA = 0
var percentB = 0

var hasA = false
var hasB = false
var team = "N"

var cap = 0
var capturing = false
var contesting = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(delta):
	contesting = hasA and hasB
	$CanvasLayer/Panel/Contesting.visible = contesting
	$CanvasLayer/Panel/Capturing.visible = capturing and not contesting
	$CanvasLayer/Panel/ProgressBar.value = cap
	$CanvasLayer/Panel/ProgressBar.visible = (cap > 0) or capturing
	
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
			if team == "B" and cap != 5:
				capturing = true
			else:
				team = "A"
				capturing = false
				cap = 0
				$Step/Light.material.albedo_color = Color(0,0,1)
				$Step/Light.material.emission = Color(0,0,1)
		if hasB:
			if team == "A" and cap != 5:
				capturing = true
			else:
				team = "B"
				capturing = false
				cap = 0
				$Step/Light.material.albedo_color = Color(1,0,0)
				$Step/Light.material.emission = Color(1,0,0)
	if not (hasA or hasB):
		capturing = false
	pass


func _on_Timer_timeout():
	if capturing and not contesting:
		cap += 1
	if not capturing and not contesting and cap > 0:
		cap -= 1
	if team == "A":
		percentA = percentA + 1
		$CanvasLayer/Panel/A/A.text = str(percentA)
	if team == "B":
		percentB = percentB + 1
		$CanvasLayer/Panel/B/B.text = str(percentB)
	pass # Replace with function body.
