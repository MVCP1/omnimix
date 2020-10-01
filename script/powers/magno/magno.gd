extends Spatial


var dad

const DAMAGE_MOUSEL = 6
#const DAMAGE_MOUSER = 10
#const DAMAGE_SHIFT = 40
#const DAMAGE_E = 30
#const DAMAGE_G = 50

var mouseL = 0
var mouseR = 0
var S = 0
var E = 0
var G = 0

var waitL = 0.8
var waitR = 0.8

var waitS = 9
var waitE = 12
var waitG = 60

var defending = false

var magnetic = 0.0
var magnetic_duration = 7.0

# Called when the node enters the scene tree for the first time.
func _ready():
	dad = get_parent().get_parent()
	set_process(true)
	if (dad.is_network_master()):
		$balls.visible = false
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#POWER COOLDOWN
	mouseL = clamp(mouseL + delta, 0, waitL)
	mouseR = clamp(mouseR + delta, 0, waitR)
	S = clamp(S + delta, 0, waitS)
	E = clamp(E + delta, 0, waitE)
	G = clamp(G + delta, 0, waitG)
	
	
	dad.rpc("defend", 1.1, 0.5, dad.name + "_pass")
	
	var number = 0
	for b in $Area.get_overlapping_bodies():
		if b.is_in_group("player"):
			if b.team == dad.team:
				if b != dad:
					number += 1
					b.rpc("defend", 0.9, 0.5, dad.name + "_pass")
					if defending:
						b.rpc("defend", 0.75, 0.5, dad.name + "_rmouse")
	$Node2D/Panel/Number.text = str(number)
	
	
	magnetic = clamp(magnetic - delta, 0, magnetic_duration)
	
	
	#INPUTS
	if dad.is_network_master() and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		
		if Input.is_action_pressed("mouse_right") and dad.stunned <= 0:
			RMOUSE()
		else:
			defending = false
		
		rpc("defending", defending)
		
		if defending:
			dad.rpc("defend", 0.75, 0.1, dad.name + "_rmouse")
		elif dad.stunned <= 0:
			if Input.is_action_pressed("mouse_left"):
				LMOUSE()
			
			if Input.is_action_just_pressed("shift"):
				SHIFT()
			if Input.is_action_just_pressed("e"):
				E()
			if Input.is_action_just_pressed("g"):
				G()
	pass

func LMOUSE():
	if mouseL >= waitL:
		mouseL = 0
		mouseR = 0
		dad.get_node("Camera").get_node("Test").make_test(5, 1, 6)
		for p in dad.get_node("Camera").get_node("Test").point:
			if magnetic > 0:
				rpc("following_ball", dad.name, dad.get_node("Camera").get_node("Gun").global_transform.origin, p, dad.team, DAMAGE_MOUSEL*(1 + dad.power_up/200))
			else:
				rpc("ball", dad.name, dad.get_node("Camera").get_node("Gun").global_transform.origin, p, dad.team, DAMAGE_MOUSEL*(1 + dad.power_up/200))
	pass

func RMOUSE():
	if mouseR >= waitR:
		mouseR = 0
		mouseL = 0
		defending = true
	if defending:
		mouseR = 0
		mouseL = 0
	pass

func SHIFT():
	if S >= waitS:
		S = 0
		for b in $Area2.get_overlapping_bodies():
			if b.is_in_group("player"):
				if b.team != dad.team:
					if dad.get_node("Camera").get_node("Test").can_see(b):
						b.rpc("add_knockback", (b.global_transform.origin - dad.global_transform.origin).normalized()*(9-(b.global_transform.origin.distance_to(dad.global_transform.origin))))
		dad.rpc("add_knockback", (global_transform.origin - $Area2.global_transform.origin).normalized()*4)
						#dad.rpc("add_knockback", (Vector3(0,0,2).rotated(Vector3(0,1,0), dad.rotation.y)))
	pass

func E():
	if E >= waitE:
		E = 0
		dad.get_node("Camera").get_node("Test").make_test(20, 0, 1)
		for p in dad.get_node("Camera").get_node("Test").point:
			rpc("grab", dad.name, dad.get_node("Camera").get_node("Gun").global_transform.origin, p, dad.team, dad.get_node("Camera").get_node("Gun").global_transform.origin.distance_to(p))
	pass

func G():
	if G >= waitG:
		G = 0
		magnetic = magnetic_duration
		dad.duration = magnetic_duration
		dad.duration_value = 100
	pass




#BALL
remotesync func ball(who, loc, target, team, damage):
	$AudioStreamPlayer3D.play()
	var actor = load("res://scenes/powers/magno/ball.tscn").instance()
	actor.dad = who
	actor.look_at_from_position(loc, target, Vector3(0,1,0))
	actor.team = team
	actor.damage = damage
	get_tree().current_scene.add_child(actor)
	pass


#FOLLOWING BALL
remotesync func following_ball(who, loc, target, team, damage):
	$AudioStreamPlayer3D.play()
	var actor = load("res://scenes/powers/magno/following_ball.tscn").instance()
	actor.dad = who
	actor.look_at_from_position(loc, target, Vector3(0,1,0))
	actor.team = team
	actor.damage = damage
	get_tree().current_scene.add_child(actor)
	pass

#DEFENDING
remotesync func defending(is_defending):
	$defending.visible = is_defending
	if not (dad.is_network_master()):
		$balls.visible = not is_defending
	pass

#GRAB
remotesync func grab(who, loc, target, team, distance):
	$AudioStreamPlayer3D.play()
	var actor = load("res://scenes/powers/magno/catch.tscn").instance()
	actor.dad = who
	actor.look_at_from_position(loc, target, Vector3(0,1,0))
	actor.team = team
	actor.distance = distance
	get_tree().current_scene.add_child(actor)
	pass
