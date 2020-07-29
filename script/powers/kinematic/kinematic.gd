extends Spatial


var dad

const DAMAGE_MOUSEL = 4
const DAMAGE_MOUSER = 30
#const DAMAGE_SHIFT
const DAMAGE_E = 40
const DAMAGE_G = 20

var mouseL = 0
var mouseR = 0
var S = 0
var E = 0
var G = 0


var waitL = 0.1
var waitR = 0.5

var waitS = 7
var waitE = 12
var waitG = 60

var charge = 0.0
var charge_max = 2.0

var heal = 0

var run = 0
var run_max = 1.5
var run_speed = 3

var shocks = 2

var target
var aim_distance = 200

var storm = 0.0
var storm_duration = 10.0
var delay = 0.0
var delay_duration = 0.5

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	dad = get_parent().get_parent()
	set_process(true)
	dad.ammo = 1
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
		
	#POWER COOLDOWN
	mouseL = clamp(mouseL + delta, 0, waitL)
	mouseR = clamp(mouseR + delta, 0, waitR)
	S = clamp(S + delta, 0, waitS)
	E = clamp(E + delta, 0, waitE)
	G = clamp(G + delta, 0, waitG)
	
	
	run = clamp(run - delta, 0, storm_duration)
	
	#SHOW CHARGING
	dad.get_node("Camera/CanvasLayer/Control/charging").scale = Vector2(1,1)*(charge/charge_max)#ceil((charge/charge_max)*10)/10
	dad.get_node("Camera/CanvasLayer/Control/charging_max").visible = charge > 0
	
	#SET THUNDER TARGET
	target = [Vector2(0,aim_distance)]
	if not storm > 0:
		if E >= waitE:
			for b in get_node("BigArea").get_overlapping_bodies():
				if b.is_in_group("player") and b != dad:
					if dad.team != b.team:
						if not dad.get_node("Camera").is_position_behind(b.global_transform.origin):
							if dad.get_node("Camera").unproject_position(b.global_transform.origin).distance_to(dad.get_node("Camera/CanvasLayer/Control/aim").position) <= aim_distance:
								if dad.get_node("Camera").get_node("Test").can_see(b):
									if target[0].distance_to(dad.get_node("Camera/CanvasLayer/Control/aim").position) > dad.get_node("Camera").unproject_position(b.global_transform.origin).distance_to(dad.get_node("Camera/CanvasLayer/Control/aim").position):
										target = [dad.get_node("Camera").unproject_position(b.global_transform.origin), b]
	if target.size() > 1:
		dad.get_node("Camera/CanvasLayer/Control/enemy").position = target[0]
	dad.get_node("Camera/CanvasLayer/Control/enemy").visible = target.size() > 1
	
	#SET THUNDERSTORM
	if storm > 0:
		if delay <= 0:
			var targets = []
			for b in get_node("BigArea").get_overlapping_bodies():
				if b.is_in_group("player") and b != dad:
					if b.team != dad.team:
						targets.append(b)
			
			if targets.size() > 0:
				targets.shuffle()
				targets[0].rpc("damage", DAMAGE_G*(1 + dad.power_up/200))
			else:
				targets.append(dad)
				
			rpc("thunder",  points(targets[0].get_node("Camera").global_transform.origin+Vector3(0,20,0), targets[0].get_node("Camera").global_transform.origin), 1, true)
			delay = delay_duration
			
		storm = clamp(storm - delta, 0, storm_duration)
		delay = clamp(delay - delta, 0, delay_duration)
	
	
	
	
	#INPUTS
	if (dad.is_network_master()) and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if Input.is_action_pressed("mouse_left"):
			if not storm > 0 and charge <= 0:
				LMOUSE()
		if Input.is_action_pressed("mouse_right"):
			if not storm > 0:
				charge = clamp(charge + delta, 0, charge_max)
		if Input.is_action_just_released("mouse_right"):
			if not storm > 0:
				RMOUSE()
				charge = 0
		
		if Input.is_action_just_pressed("shift"):
			if not storm > 0:
				if S >= waitS:
					S = 0
					run = run_max
		if Input.is_action_just_released("shift"):
			if not storm > 0:
				if run > 0:
					run = 0
			
		if Input.is_action_just_pressed("e"):
			E()
		if Input.is_action_just_pressed("g"):
			G()
		
		#HEALS WHEN WALKING FORWARD
		if Input.is_action_pressed("front"):
			heal = clamp(heal+delta*2, 0, 1)
			if heal == 1:
				dad.heal(heal)
				heal = 0
		
		if run > 0:
			dad.RUNNING_MULTIPLIER = run_speed
		else:
			dad.RUNNING_MULTIPLIER = 1
	pass



func LMOUSE():
	if mouseL >= waitL:
		mouseL = 0
		var hit = 0
		var enemies = []
		for b in get_node("Area").get_overlapping_bodies():
			if b.is_in_group("player"):
				if dad.team != b.team:
					if enemies.size() < shocks:
						enemies.append(b)
					else:
						var maxd = [0,0]
						for o in enemies:
							if global_transform.origin.distance_to(o.global_transform.origin) > maxd[0]:
								maxd = [global_transform.origin.distance_to(o.global_transform.origin), o]
						if maxd[0] > global_transform.origin.distance_to(b.global_transform.origin):
							enemies.erase(maxd[1])
							enemies.append(b)
		for b in enemies:
			rpc("thunder", points(dad.get_node("Camera").get_node("Gun").global_transform.origin, b.global_transform.origin), 0.1, false)
			b.rpc("damage", DAMAGE_MOUSEL*(1 + dad.power_up/200))
		if enemies.size() < shocks:
			if not dad.get_node("Camera").get_node("Test").make_test(6, 2, shocks-enemies.size()):
				if not dad.get_node("Camera").get_node("Test").make_test(10, 2, shocks-enemies.size(), Vector3(0,-1,-3)):
					dad.get_node("Camera").get_node("Test").make_test(6, 2, shocks-enemies.size())
			for n in dad.get_node("Camera").get_node("Test").point:
				rpc("thunder", points(dad.get_node("Camera").get_node("Gun").global_transform.origin, n), 0.1, false)
	pass

func RMOUSE():
	if mouseR >= waitR:
		mouseR = 0
		charge = ceil((charge/charge_max)*10)/10
		dad.get_node("Camera").get_node("Test").make_test(100, 0, 1)
		for p in dad.get_node("Camera").get_node("Test").point:
			rpc("plasma_ball", dad.name, dad.get_node("Camera").get_node("Gun").global_transform.origin, p, dad.team, DAMAGE_MOUSER*(1 + dad.power_up/200), charge)
	pass

func E():
	if E >= waitE and target.size() > 1:
		E = 0
		target[1].rpc("damage", DAMAGE_E*(1 + dad.power_up/200))
		rpc("thunder",  points(target[1].get_node("Camera").global_transform.origin+Vector3(0,20,0), target[1].get_node("Camera").global_transform.origin), 1, true)
	pass

func G():
	if G >= waitG:
		G = 0
		storm = storm_duration
		run = storm_duration
		dad.duration = storm_duration
		dad.duration_value = 100
	pass



func points(start, end):
	var spread = 0.3#0.2
	var alpha = 1#0.5
	
	var all = []
	
	all.append(start)
	
	var segs = start.distance_to(end) / alpha
	var add = (end - start)/segs
	
	var i = 1
	while i < segs:
		all.append(Vector3(all[i-1].x + add.x + nextGaussian3(0, 0.3, -1, 1)*spread, all[i-1].y + add.y + nextGaussian3(0, 0.3, -1, 1)*spread, all[i-1].z + add.z + nextGaussian3(0, 0.3, -1, 1)*spread))
		i += 1
	
	all.append(end)
	return all




#PLASMA_BALL
remotesync func plasma_ball(who, loc, point, team, damage, charging):
	$AudioStreamPlayer3D.play()
	var actor = load("res://scenes/powers/kinematic/plasma_ball.tscn").instance()
	actor.dad = who
	actor.damage = damage * charging
	actor.get_node("CollisionShape").scale = actor.get_node("CollisionShape").scale*charging
	actor.look_at_from_position(loc, point, Vector3(0,1,0))
	actor.team = team
	get_tree().current_scene.add_child(actor)
	pass

#THUNDER
remotesync func thunder(points, time, explosion):
	if explosion:
		var partic = load("res://particles/explosion.tscn").instance()
		partic.global_translate(points[-1])
		get_tree().current_scene.add_child(partic)
	var i = 0
	while i < (points.size()-1):
		var actor = load("res://particles/thunder.tscn").instance()
		actor.scale.z = points[i].distance_to(points[i+1])
		actor.look_at_from_position((points[i] + ((points[i+1]-points[i])*0.5)), points[i+1], Vector3(0,1,0))
		actor.get_node("Timer").wait_time = time
		get_tree().current_scene.add_child(actor)
		i += 1
	pass

#HITSCAN
remotesync func hitscan(point, loc):
	$AudioStreamPlayer3D.play()
	var partic = load("res://particles/explosion.tscn").instance()
	partic.global_translate(point)
	get_tree().current_scene.add_child(partic)
	var actor = load("res://particles/beam.tscn").instance()
	actor.scale.z = loc.distance_to(point)
	actor.look_at_from_position((loc + ((point-loc)*0.5)), point, Vector3(0,1,0))
	get_tree().current_scene.add_child(actor)
	pass




#SPREAD FUNCTION

static func nextGaussian() -> float:
	var v1:float
	var v2:float
	var s:float
	var firstPass = true

	while firstPass or s >= 1.0 or s == 0:
		v1 = 2.0 * randf() - 1.0
		v2 = 2.0 * randf() - 1.0
		s = v1 * v1 + v2 * v2
		firstPass = false

	s = sqrt((-2.0 * log(s)) / s)

	return v1 * s

static func nextGaussian2(mean:float, standard_deviation:float) -> float:
	return mean + nextGaussian() * standard_deviation

static func nextGaussian3(mean:float, standard_deviation:float, _min:float, _max:float) -> float:
	var x:float
	var firstPass = true

	while firstPass or x < _min or x > _max:
		x = nextGaussian2(mean, standard_deviation)
		firstPass = false
	return x
