extends Spatial


var dad
var dad_team = "N"

const DAMAGE_MOUSEL = 2
const DAMAGE_MOUSER = 20
#const DAMAGE_SHIFT = 40
#const DAMAGE_E = 30
#const DAMAGE_G = 50

var mouseL = 0
var mouseR = 0
var S = 0
var E = 0
var G = 0


var waitL = 0.05
var waitR = 1

var waitS = 0.1
var waitE = 18
var waitG = 60

var rgb = Vector3(1,0,0)

var target = null
var target_distance = 1

var white = 0
var white_duration = 10

var light
var aim_distance = 200

# Called when the node enters the scene tree for the first time.
func _ready():
	dad = get_parent().get_parent()
	set_process(true)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#GET DAD TEAM
	if(dad.is_in_group("teamA")):
		dad_team = "A"
	elif(dad.is_in_group("teamB")):
		dad_team = "B"
		
	#POWER COOLDOWN
	mouseL = clamp(mouseL + delta, 0, waitL)
	mouseR = clamp(mouseR + delta, 0, waitR)
	S = clamp(S + delta, 0, waitS)
	E = clamp(E + delta, 0, waitE)
	G = clamp(G + delta, 0, waitG)
	
	white = clamp(white - delta, 0, white_duration)
	if white == 0 and rgb == Vector3(1,1,1):
		rgb = Vector3(1,0,0)
	
	light = [Vector2(0,aim_distance)]
	if E >= waitE:
		for b in get_node("BigArea").get_overlapping_bodies():
			if b.is_in_group("player") and b != dad:
				if(dad.is_in_group("teamA") and b.is_in_group("teamB")) or (dad.is_in_group("teamB") and b.is_in_group("teamA")):
					if not dad.get_node("Camera").is_position_behind(b.global_transform.origin):
						if dad.get_node("Camera").unproject_position(b.global_transform.origin).distance_to(dad.get_node("Camera/CanvasLayer/Control/aim").position) <= aim_distance:
							if dad.get_node("Camera").get_node("Test").can_see(b):
								if light[0].distance_to(dad.get_node("Camera/CanvasLayer/Control/aim").position) > dad.get_node("Camera").unproject_position(b.global_transform.origin).distance_to(dad.get_node("Camera/CanvasLayer/Control/aim").position):
									light = [dad.get_node("Camera").unproject_position(b.global_transform.origin), b]
	if light.size() > 1:
		dad.get_node("Camera/CanvasLayer/Control/enemy").position = light[0]
	dad.get_node("Camera/CanvasLayer/Control/enemy").visible = light.size() > 1
	
	#INPUTS
	if (dad.is_network_master()) and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if Input.is_action_pressed("mouse_left"):
			LMOUSE()
		if Input.is_action_just_released("mouse_left"):
			rpc("laser", false)
		if Input.is_action_pressed("mouse_right"):
			rpc("laser", false)
			RMOUSE()
		
		if Input.is_action_just_pressed("shift"):
			if white <= 0:
				SHIFT()
		if Input.is_action_just_pressed("e"):
			E()
		if Input.is_action_just_pressed("g"):
			G()
	pass

func LMOUSE():
	if mouseL >= waitL and mouseR >= waitR:
		mouseL = 0
		if dad.get_node("Camera").get_node("Test").make_test(15, 0, 1):
			for b in dad.get_node("Camera").get_node("Test").body:
				if b != null and b != target:
					if b.is_in_group("player"):
						if rgb.x == 1:
							if(dad.is_in_group("teamA") and b.is_in_group("teamB")) or (dad.is_in_group("teamB") and b.is_in_group("teamA")):
								target = b
						if(dad.is_in_group("teamA") and b.is_in_group("teamA")) or (dad.is_in_group("teamB") and b.is_in_group("teamB")):
							if rgb.y == 1 or rgb.z == 1:
								target = b
							for p in dad.get_node("Camera").get_node("Test").point:
								rpc("laser", true, p, dad.get_node("Camera").get_node("Gun").global_transform.origin, rgb)
		
		if target == null:
			for p in dad.get_node("Camera").get_node("Test").point:
				rpc("laser", true, p, dad.get_node("Camera").get_node("Gun").global_transform.origin, rgb)
		else:
			for p in dad.get_node("Camera").get_node("Test").point:
				if p.distance_to(target.global_transform.origin) <= target_distance:
					if rgb.x == 1:
						if(dad.is_in_group("teamA") and target.is_in_group("teamB")) or (dad.is_in_group("teamB") and target.is_in_group("teamA")):
							target.rpc("damage", DAMAGE_MOUSEL*(1 + dad.power_up/200))
							rpc("laser", true, target.global_transform.origin, dad.get_node("Camera").get_node("Gun").global_transform.origin, rgb)
						else:
							target = null
					if(dad.is_in_group("teamA") and target.is_in_group("teamA")) or (dad.is_in_group("teamB") and target.is_in_group("teamB")):
						if rgb.y == 1:
							target.rpc("heal", DAMAGE_MOUSEL)
							dad.rpc("heal", DAMAGE_MOUSEL/2)
						if rgb.z == 1:
							target.rpc("power_up", DAMAGE_MOUSEL)
							dad.rpc("power_up", DAMAGE_MOUSEL/2)
						rpc("laser", true, target.global_transform.origin, dad.get_node("Camera").get_node("Gun").global_transform.origin, rgb)
					else:
						target = null
				else:
					target = null
	pass

func RMOUSE():
	if mouseR >= waitR:
		mouseR = 0
		dad.get_node("Camera").get_node("Test").make_test(100, 0, 1)
		for p in dad.get_node("Camera").get_node("Test").point:
			rpc("wave_bomb", dad.name, dad.get_node("Camera").get_node("Gun").global_transform.origin, p, dad_team, rgb, DAMAGE_MOUSER, (1 + dad.power_up/200))
	pass

func SHIFT():
	if S >= waitS:
		S = 0
		if rgb == Vector3(1,0,0):
			rgb = Vector3(0,1,0)
		elif rgb == Vector3(0,1,0):
			rgb = Vector3(0,0,1)
		elif rgb == Vector3(0,0,1):
			rgb = Vector3(1,0,0)
	pass

func E():
	if E >= waitE and light.size() > 1:
		E = 0
		rpc("light", dad.name, light[1].name, dad_team, 8)
	pass

func G():
	if G >= waitG:
		G = 0
		white = white_duration
		rgb = Vector3(1,1,1)
		dad.duration = white_duration
		dad.duration_value = 100
	pass





#LASER
remotesync func laser(on:bool = false, point:Vector3 = Vector3(0,0,0), loc:Vector3 = Vector3(0,0,0), color:Vector3 = Vector3(0,0,0)):
	$laser.visible = on
	if on:
		$laser.scale.z = loc.distance_to(point)
		$laser.look_at_from_position((loc + ((point-loc)*0.5)), point, Vector3(0,1,0))
		$laser/P.process_material.color = Color(color.x, color.y, color.z, 1)
		$laser/P.draw_pass_1.material.emission = Color(color.x, color.y, color.z, 1)
	pass

#WAVE BOMB
remotesync func wave_bomb(who, loc, target, team, color, damage, bonus):
	$AudioStreamPlayer3D.play()
	var actor = load("res://scenes/powers/wise/wave_bomb.tscn").instance()
	actor.dad = who
	actor.look_at_from_position(loc, target, Vector3(0,1,0))
	actor.add_to_group("team"+team)
	actor.rgb = color
	actor.damage = damage
	actor.bonus = bonus
	get_tree().current_scene.add_child(actor)
	pass

#LIGHT
remotesync func light(who, target_name, team, time):
	$AudioStreamPlayer3D.play()
	var actor = load("res://scenes/powers/wise/light.tscn").instance()
	actor.dad = who
	actor.target = target_name
	actor.add_to_group("team"+team)
	actor.time = time
	get_tree().current_scene.add_child(actor)
	pass
