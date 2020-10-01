extends Spatial


var dad

const DAMAGE_MOUSEL = 4
#const DAMAGE_MOUSER = 10
#const DAMAGE_SHIFT = 40
const DAMAGE_E = 20
const DAMAGE_G = 40

var mouseL = 0
var mouseR = 0
var S = 0
var E = 0
var G = 0

var charge = 0.0
var charge_max = 1.5

var waitL = 0.08
var waitR = 0

var waitS = 1#8
var waitE = 1#8
var waitG = 1#60

var ammo_max = 200
var reload = 0
var reload_time = 4

var run_speed = 0.5
var heal = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	dad = get_parent().get_parent()
	set_process(true)
	dad.ammo = ammo_max
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#POWER COOLDOWN
	mouseL = clamp(mouseL + (delta*(charge/charge_max)), 0, waitL+1)
	mouseR = clamp(mouseR + delta, 0, waitR)
	S = clamp(S + delta, 0, waitS)
	E = clamp(E + delta, 0, waitE)
	G = clamp(G + delta, 0, waitG)
	
	if reload > 0:
		reload = clamp(reload - delta, 0, reload_time)
		if reload == 0:
			dad.ammo = ammo_max
	
	
	#SHOW CHARGING
	dad.get_node("Camera/CanvasLayer/Control/charging").scale = Vector2(1,1)*(charge/charge_max)
	dad.get_node("Camera/CanvasLayer/Control/charging_max").visible = charge > 0
	
	
	#HEALS WHEN NOT WALKING
	if not (Input.is_action_pressed("front") or Input.is_action_pressed("back") or Input.is_action_pressed("left") or Input.is_action_pressed("right")):
		heal = clamp(heal+delta*2, 0, 1)
		if heal == 1:
			dad.heal(heal)
			heal = 0
	
	if dad.stunned > 0:
		charge = 0
	
	#INPUTS
	if dad.is_network_master() and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and dad.stunned <= 0:
		if Input.is_action_pressed("mouse_left"):
			if dad.ammo > 0 and reload == 0 and charge > 0:
				LMOUSE()
		if reload == 0:
			if Input.is_action_pressed("mouse_right"):
				charge = clamp(charge + delta, 0, charge_max)
				if Input.is_action_pressed("mouse_left"):
					dad.RUNNING_MULTIPLIER = run_speed*run_speed
				else:
					dad.RUNNING_MULTIPLIER = run_speed
			else:
				charge = clamp(charge - delta, 0, charge_max)
				dad.RUNNING_MULTIPLIER = 1
		if Input.is_action_just_pressed("shift"):
			SHIFT()
		if Input.is_action_just_pressed("e"):
			E()
		if Input.is_action_just_pressed("g"):
			G()
		if Input.is_action_just_pressed("r") or (dad.ammo == 0 and (Input.is_action_pressed("mouse_left") or Input.is_action_pressed("mouse_right"))):
			if dad.ammo < ammo_max and reload == 0:
				charge = 0
				dad.RUNNING_MULTIPLIER = 1
				reload = reload_time
	pass

func LMOUSE():
	if mouseL >= waitL:
		mouseL = 0
		dad.ammo = clamp(dad.ammo - 1, 0, ammo_max)
		dad.get_node("Camera").get_node("Test").make_test(100, 6, 1)
		for p in dad.get_node("Camera").get_node("Test").point:
			rpc("hitscan", p, dad.get_node("Camera").get_node("Gun").global_transform.origin)
		for b in dad.get_node("Camera").get_node("Test").body:
			if b != null:
				if b.is_in_group("player"):
					if dad.team != b.team:
						b.rpc("damage", DAMAGE_MOUSEL*(1 + dad.power_up/200))
	pass

func SHIFT():
	if S >= waitS:
		S = 0
		dad.get_node("Camera").get_node("Test").make_test(100, 0, 1)
		for p in dad.get_node("Camera").get_node("Test").point:
			rpc("ring_shield", dad.name, dad.get_node("Camera").get_node("Gun").global_transform.origin, p, dad.team)
	pass

func E():
	if E >= waitE:
		E = 0
		dad.get_node("Camera").get_node("Test").make_test(100, 0, 1)
		for p in dad.get_node("Camera").get_node("Test").point:
			rpc("rock", dad.name, dad.get_node("Camera").get_node("Gun").global_transform.origin, p, dad.team, DAMAGE_E*(1 + dad.power_up/200))
	pass

func G():
	if G >= waitG:
		G = 0
		for b in $Area.get_overlapping_bodies():
			if b.is_in_group("player"):
				if dad.team != b.team:
					b.rpc("damage", DAMAGE_G)
					b.rpc("add_knockback", Vector3(0,1,0))
					b.rpc("stun", 3.0)
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

#RING SHIELD
remotesync func ring_shield(who, loc, target, team):
	var actor = load("res://scenes/powers/steady/ring_shield.tscn").instance()
	actor.dad = who
	actor.look_at_from_position(loc-Vector3(0,2,0), Vector3(target.x,loc.y,target.z), Vector3(0,1,0))
	actor.team = team
	get_tree().current_scene.add_child(actor)
	pass

#ROCK
remotesync func rock(who, loc, target, team, damage):
	$AudioStreamPlayer3D.play()
	var actor = load("res://scenes/powers/steady/rock.tscn").instance()
	actor.dad = who
	actor.look_at_from_position(loc, target, Vector3(0,1,0))
	actor.team = team
	actor.damage = damage
	get_tree().current_scene.add_child(actor)
	pass
