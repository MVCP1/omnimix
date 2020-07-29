extends Spatial


var dad

const DAMAGE_MOUSEL = 10
const DAMAGE_MOUSER = 10
const DAMAGE_SHIFT = 40
const DAMAGE_E = 30
const DAMAGE_G = 50

var mouseL = 0
var mouseR = 0
var S = 0
var E = 0
var G = 0


var waitL = 0.3
var waitR = 0.5

var waitS = 8
var waitE = 10
var waitG = 60

var ammo_max = 20
var reload = 0
var reload_time = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	dad = get_parent().get_parent()
	set_process(true)
	dad.ammo = ammo_max
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#POWER COOLDOWN
	mouseL = clamp(mouseL + delta, 0, waitL)
	mouseR = clamp(mouseR + delta, 0, waitR)
	S = clamp(S + delta, 0, waitS)
	E = clamp(E + delta, 0, waitE)
	G = clamp(G + delta, 0, waitG)
	
	if reload > 0:
		reload = clamp(reload - delta, 0, reload_time)
		if reload == 0:
			dad.ammo = ammo_max
	
	#INPUTS
	if (dad.is_network_master()) and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if Input.is_action_pressed("mouse_left"):
			if dad.ammo > 0 and reload == 0:
				LMOUSE()
		if Input.is_action_pressed("mouse_right"):
			if dad.ammo > 0 and reload == 0:
				RMOUSE()
		if Input.is_action_just_pressed("shift"):
			SHIFT()
		if Input.is_action_just_pressed("e"):
			E()
		if Input.is_action_just_pressed("g"):
			G()
		if Input.is_action_just_pressed("r") or (dad.ammo == 0 and (Input.is_action_pressed("mouse_left") or Input.is_action_pressed("mouse_right"))):
			if dad.ammo < ammo_max and reload == 0:
				reload = reload_time
	pass

func LMOUSE():
	if mouseL >= waitL:
		mouseL = 0
		dad.ammo = clamp(dad.ammo - 1, 0, ammo_max)
		dad.get_node("Camera").get_node("Test").make_test(100, 0, 1)
		for p in dad.get_node("Camera").get_node("Test").point:
			rpc("shoot", dad.name, dad.get_node("Camera").get_node("Gun").global_transform.origin, p, dad.team, DAMAGE_MOUSEL*(1 + dad.power_up/200))
	pass

func RMOUSE():
	if mouseR >= waitR:
		mouseR = 0
		dad.ammo = clamp(dad.ammo - 1, 0, ammo_max)
		dad.get_node("Camera").get_node("Test").make_test(100, 0, 1)
		for p in dad.get_node("Camera").get_node("Test").point:
			rpc("hitscan", p, dad.get_node("Camera").get_node("Gun").global_transform.origin)
		for b in dad.get_node("Camera").get_node("Test").body:
			if b != null:
				if b.is_in_group("player"):
					if dad.team != b.team:
						b.rpc("damage", DAMAGE_MOUSER*(1 + dad.power_up/200))
	pass

func SHIFT():
	if S >= waitS:
		S = 0
		dad.get_node("Camera").get_node("Test").make_test(100, 0, 1)
		for p in dad.get_node("Camera").get_node("Test").point:
			rpc("hitscan", p, dad.get_node("Camera").get_node("Gun").global_transform.origin)
		for b in dad.get_node("Camera").get_node("Test").body:
			if b != null:
				if b.is_in_group("player"):
					if dad.team != b.team:
						b.rpc("damage", DAMAGE_SHIFT*(1 + dad.power_up/200))
	pass

func E():
	if E >= waitE:
		E = 0
		dad.get_node("Camera").get_node("Test").make_test(100, 0, 1)
		for p in dad.get_node("Camera").get_node("Test").point:
			rpc("bomb", dad.name, dad.get_node("Camera").get_node("Gun").global_transform.origin, p, dad.team, DAMAGE_E*(1 + dad.power_up/200))
	pass

func G():
	if G >= waitG:
		G = 0
		dad.get_node("Camera").get_node("Test").make_test(100, 0, 1)
		for p in dad.get_node("Camera").get_node("Test").point:
			rpc("bazuca", dad.name, dad.get_node("Camera").get_node("Gun").global_transform.origin, p, dad.team, DAMAGE_G*(1 + dad.power_up/200))
	pass


#SHOOT
remotesync func shoot(who, loc, target, team, damage):
	$AudioStreamPlayer3D.play()
	var actor = load("res://scenes/powers/blank/bullet.tscn").instance()
	actor.dad = who
	actor.look_at_from_position(loc, target, Vector3(0,1,0))
	actor.team = team
	actor.damage = damage
	get_tree().current_scene.add_child(actor)
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

#BOMB
remotesync func bomb(who, loc, target, team, damage):
	$AudioStreamPlayer3D.play()
	var actor = load("res://scenes/powers/blank/bomb.tscn").instance()
	actor.dad = who
	actor.look_at_from_position(loc, target, Vector3(0,1,0))
	actor.team = team
	actor.damage = damage
	get_tree().current_scene.add_child(actor)
	pass

#BAZUCA
remotesync func bazuca(who, loc, target, team, damage):
	$AudioStreamPlayer3D.play()
	var actor = load("res://scenes/powers/blank/bazuca.tscn").instance()
	actor.dad = who
	actor.look_at_from_position(loc, target, Vector3(0,1,0))
	actor.team != team
	actor.damage = damage
	get_tree().current_scene.add_child(actor)
	pass
