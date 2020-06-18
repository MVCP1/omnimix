extends Spatial


var dad
var dad_team = "N"


var mouseL = 0
var mouseR = 0


var waitL = 0.3
var waitR = 0.5

var waitS = 8
var waitE = 10
var waitG = 50

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(dad.is_in_group("teamA")):
		dad_team = "A"
	elif(dad.is_in_group("teamB")):
		dad_team = "B"
	mouseL = clamp(mouseL + delta, 0, waitL)
	mouseR = clamp(mouseR + delta, 0, waitR)
	pass

func _init():
	dad = get_parent()
	set_process(true)
	pass

func LMOUSE():
	if mouseL >= waitL:
		mouseL = 0
		dad.get_node("Camera").get_node("Test").force_raycast_update()
		if dad.get_node("Camera").get_node("Test").is_colliding():
			rpc("shoot", dad.name, dad.get_node("Camera").get_node("Gun").global_transform.origin, dad.get_node("Camera").get_node("Test").get_collision_point(), dad_team)
	pass

func RMOUSE():
	if mouseR >= waitR:
		mouseR = 0
		dad.get_node("Camera").get_node("Test").force_raycast_update()
		if dad.get_node("Camera").get_node("Test").is_colliding():
			rpc("hitscan", dad.get_node("Camera").get_node("Test").get_collision_point(), dad.get_node("Camera").get_node("Gun").global_transform.origin)
			if dad.get_node("Camera").get_node("Test").get_collider().is_in_group("player"):
				if(dad.is_in_group("teamA") and dad.get_node("Camera").get_node("Test").get_collider().is_in_group("teamB")) or (dad.is_in_group("teamB") and dad.get_node("Camera").get_node("Test").get_collider().is_in_group("teamA")):
					dad.get_node("Camera").get_node("Test").get_collider().rpc("damage", 10)
	pass

func SHIFT():
	dad.get_node("Camera").get_node("Test").force_raycast_update()
	if dad.get_node("Camera").get_node("Test").is_colliding():
		rpc("hitscan", dad.get_node("Camera").get_node("Test").get_collision_point(), dad.get_node("Camera").get_node("Gun").global_transform.origin)
		if dad.get_node("Camera").get_node("Test").get_collider().is_in_group("player"):
			if(dad.is_in_group("teamA") and dad.get_node("Camera").get_node("Test").get_collider().is_in_group("teamB")) or (dad.is_in_group("teamB") and dad.get_node("Camera").get_node("Test").get_collider().is_in_group("teamA")):
				dad.get_node("Camera").get_node("Test").get_collider().rpc("damage", 30)
	pass

func E():
	rpc("bomb", dad.name, dad.get_node("Camera").get_node("Gun").global_transform.origin, dad.get_node("Camera").get_node("Test").get_collision_point(), dad_team)
	pass

func G():
	rpc("bazuca", dad.name, dad.get_node("Camera").get_node("Gun").global_transform.origin, dad.get_node("Camera").get_node("Test").get_collision_point(), dad_team)
	pass




#SHOOT
remotesync func shoot(who, loc, target, team):
	$AudioStreamPlayer3D.play()
	var actor = load("res://scenes/powers/bullet.tscn").instance()
	actor.dad = who
	actor.look_at_from_position(loc, target, Vector3(0,1,0))
	actor.add_to_group("team"+team)
	get_parent().get_parent().add_child(actor)
	pass

#HITSCAN
remotesync func hitscan(point, loc):
	$AudioStreamPlayer3D.play()
	var partic = load("res://particles/explosion.tscn").instance()
	partic.global_translate(point)
	get_parent().get_parent().add_child(partic)
	var actor = load("res://particles/beam.tscn").instance()
	actor.scale.z = loc.distance_to(point)
	actor.look_at_from_position((loc + ((point-loc)*0.5)), point, Vector3(0,1,0))
	get_parent().get_parent().add_child(actor)
	pass

#BOMB
remotesync func bomb(who, loc, target, team):
	$AudioStreamPlayer3D.play()
	var actor = load("res://scenes/powers/bomb.tscn").instance()
	actor.dad = who
	actor.look_at_from_position(loc, target, Vector3(0,1,0))
	actor.add_to_group("team"+team)
	get_parent().get_parent().add_child(actor)
	pass

#BAZUCA
remotesync func bazuca(who, loc, target, team):
	$AudioStreamPlayer3D.play()
	var actor = load("res://scenes/powers/bazuca.tscn").instance()
	actor.dad = who
	actor.look_at_from_position(loc, target, Vector3(0,1,0))
	actor.add_to_group("team"+team)
	get_parent().get_parent().add_child(actor)
	pass
