extends Spatial


var dad
var dad_team = "N"


var mouseL = 0
var mouseR = 0
var S = 0
var E = 0
var G = 0


var waitL = 1.5
var waitR = 0.2

var waitS = 5
var waitE = 15
var waitG = 60

var wind = false

var jump = 2

var ult = 0
var ult_time = 15


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#GET DAD TEAM
	if(dad.is_in_group("teamA")):
		dad_team = "A"
	elif(dad.is_in_group("teamB")):
		dad_team = "B"
		
	#POWER COOLDOWN
	mouseR = clamp(mouseR + delta, 0, waitR)
	S = clamp(S + delta, 0, waitS)
	E = clamp(E + delta, 0, waitE)
	if dad.on_floor:
		jump = 2
	
	if ult > 0:
		ult = clamp(ult - delta, 0, ult_time)
		#INFINITE JUMPS
		jump = 2
		#FASTER GUN
		mouseL = clamp(mouseL + (delta*3), 0, waitL)
		mouseR = 0
	else:
		mouseL = clamp(mouseL + delta, 0, waitL)
		G = clamp(G + delta, 0, waitG)
	
	dad.confirm = wind
	if wind:
		if dad.get_node("Camera").get_node("Test").make_test(100, 0, 1):
			get_node("wind_fade").visible = true
			get_node("wind_fade").global_transform.origin = dad.get_node("Camera").get_node("Test").point[0]
			if dad.get_node("Camera").get_node("Test").normal[0].y == 1:
				get_node("wind_fade").get_child(0).material.set_albedo(Color(0,1,1,0.1))
			else:
				get_node("wind_fade").get_child(0).material.set_albedo(Color(1,0.5,0.5,0.1))
		else:
			get_node("wind_fade").visible = false
	
	#INPUTS
	if (dad.is_network_master()) and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if Input.is_action_pressed("mouse_left"):
			if not wind:
				LMOUSE()
			else:
				mouseL = 0
				wind = false
				get_node("wind_fade").queue_free()
				if get_node("wind_fade").visible and get_node("wind_fade").get_child(0).material.albedo_color == Color(0,1,1,0.1):
					E = 0
					rpc("wind", dad.name, dad.get_node("Camera").get_node("Test").get_collision_point(), dad_team)
		if Input.is_action_pressed("mouse_right"):
			if not wind:
				if mouseR >= waitR:
					dad.get_node("Camera").fov = 25
					dad.SENSITIVITY = -0.000357
					dad.RUNNING_MULTIPLIER = 0.357
			else:
				wind = false
				mouseR = 0
				get_node("wind_fade").queue_free()
		else:
			dad.get_node("Camera").fov = 70
			dad.SENSITIVITY = -0.001
			dad.RUNNING_MULTIPLIER = 1
		
			if Input.is_action_just_pressed("shift"):
				SHIFT()
			if Input.is_action_just_pressed("e"):
				E()
			if Input.is_action_just_pressed("g"):
				G()
		
		if Input.is_action_just_pressed("space"):
			SPACE()
	pass

func _init():
	dad = get_parent()
	set_process(true)
	pass

func LMOUSE():
	if mouseL >= waitL:
		mouseL = 0
		dad.get_node("Camera").get_node("Test").make_test(100, 0, 1)
		for p in dad.get_node("Camera").get_node("Test").point:
			rpc("hitscan", p, dad.get_node("Camera").get_node("Gun").global_transform.origin)
		for b in dad.get_node("Camera").get_node("Test").body:
			if b != null:
				if b.is_in_group("player"):
					if(dad.is_in_group("teamA") and b.is_in_group("teamB")) or (dad.is_in_group("teamB") and b.is_in_group("teamA")):
						b.rpc("damage", 40)
	pass

func SHIFT():
	if S >= waitS:
		S = 0
		dad.y_vel = dad.JUMP_FORCE*2
	pass

func E():
	if E >= waitE:
		if not wind:
			var actor = load("res://scenes/powers/traveller/wind_fade.tscn").instance()
			actor.global_translate(dad.get_node("Camera").get_node("Test").get_collision_point())
			actor.dad = dad.name
			add_child(actor)
			wind = true
	pass

func G():
	if G >= waitG:
		G = 0
		ult = ult_time
		dad.get_node("Camera").fov = 70
		dad.SENSITIVITY = -0.001
		dad.RUNNING_MULTIPLIER = 1
		
		dad.duration = ult_time
		dad.duration_value = 100
	pass

func SPACE():
	if not dad.on_floor:
		if jump > 0:
			jump -= 1
			dad.y_vel = dad.JUMP_FORCE


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

#WIND
remotesync func wind(who, target, team):
	var partic = load("res://particles/wind_up.tscn").instance()
	partic.global_translate(target)
	get_parent().get_parent().add_child(partic)
	var actor = load("res://scenes/powers/traveller/wind.tscn").instance()
	actor.dad = who
	actor.global_translate(target)
	actor.add_to_group("team"+team)
	get_parent().get_parent().add_child(actor)
	pass
