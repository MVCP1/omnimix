extends KinematicBody


export var moving = false
export var cicle_time = 1.0
var time = 0
var add = true

# Declare member variables here. Examples:
export var team = "N"

var life = 100
var defence = []

var power_up = 0
var power_up_duration = 2
var power_up_max = 0
var power_up_max_duration = 1
var power_up_delay = 0.2

const JUMP_FORCE = 10
const GRAVITY = 0.5#0.98/2
const MAX_FALL_SPEED = 15

var y_vel = 0

var seen = 0

var knockback = Vector3()

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("player")
	$Sprite3D.texture = $Sprite3D/Viewport.get_texture()
	$Sprite3D2.texture = $Sprite3D2/Viewport.get_texture()
	$skin/outline.set_surface_material(0, $skin/outline.get_surface_material(0).duplicate())
	pass # Replace with function body.

remotesync func damage(value):
	var result = value
	for d in defence:
		result = result*d[0]
	life = clamp(life-result, 0, 100)
	if life <= 0:
		life = 100
#	if not (is_network_master()):
#		$Healthbar.visible = true
	pass

remotesync func heal(value):
	life = clamp(life+value, 0, 100)
#	if not (is_network_master()):
#		$Healthbar.visible = true
	pass

remotesync func power_up(value):
	power_up = clamp(power_up+value, 0, 100)
	if power_up >= 100:
		power_up_max = power_up_max_duration
	else:
		power_up_max = power_up_delay
	pass

remotesync func see(time):
	if time > seen:
		seen = time
	pass

remotesync func defend(value, time, giver):
	var has = false
	for d in defence:
		if not has:
			if d[2] == giver:
				d[1] = time
				has = true
	if not has:
		defence.append([value, time, giver])

func _physics_process(delta):
	$Sprite3D/Viewport/ProgressBar.value = life
	
	$skin/outline.visible = not get_tree().current_scene.get_node(str(gamestate.player_info.net_id)).team == team
	
	$Sprite3D2.visible = power_up > 0
	$Sprite3D2/Viewport/ProgressBar.value = power_up
	if power_up_max <= 0:
		power_up = clamp(power_up - (100*delta/power_up_duration), 0, 100)
	else:
		power_up_max = clamp(power_up_max - delta, 0, 100)
	
	#DEFENCE TIMER
	for d in defence:
		d[1] = d[1] - delta
		if d[1] <= 0:
			defence.erase(d)
	
	
	var move = Vector3()
	
	
	if moving:
		if add:
			time = clamp(time + delta, (-1)*cicle_time, cicle_time)
			move.z = 10
			if time >= cicle_time:
				add = false
		else:
			time = clamp(time - delta, (-1)*cicle_time, cicle_time)
			move.z = -10
			if time <= (-1)*cicle_time:
				add = true
	
	#ADDING GRAVITY
	if knockback.y > 1:
		y_vel = knockback.y
		knockback.y -= GRAVITY
	
	move.y = y_vel
	
	move = move.rotated(Vector3(0, 1, 0), rotation.y)
	
	if move + knockback != Vector3(0,0,0):
		if knockback == Vector3(0,0,0):
			move_and_slide(Vector3(move.x, move.y, move.z), Vector3(0, 1, 0))
		else:
			move_and_slide(Vector3(move.x*0.5 + knockback.x, move.y, move.z*0.5 + knockback.z), Vector3(0, 1, 0))
	
	if seen > 0:
		seen -= delta
	if seen < 0:
		seen = 0
	
	#PROCESSES IF IS BEING SEEN
	being_seen()
	
	
	#GRAVITY
	y_vel -= GRAVITY
	#FALL SPEED LIMIT
	if y_vel < -MAX_FALL_SPEED:
		y_vel = -MAX_FALL_SPEED
	
	#HITTING A CEILING STOPS THE JUMP
	if (is_on_ceiling() and y_vel > 0):# or is_on_floor():
		y_vel = 0
		knockback.y = 0
	pass
	
	
	#KNOCKBACK SLOWING DOWN
	if abs(knockback.x) < 1 and abs(knockback.y) < 1 and abs(knockback.z) < 1:
		knockback = Vector3(0,0,0)
	else:
		if is_on_wall():
			knockback.x *= 0.8
			knockback.y *= 0.9
			knockback.z *= 0.8
		else:
			knockback *= 0.9

func being_seen():
	if seen > 0:
		$skin/outline.get_surface_material(0).flags_no_depth_test = not get_tree().current_scene.get_node(str(gamestate.player_info.net_id)).get_node("Camera").get_node("Test").can_see(self)
	else:
		$skin/outline.get_surface_material(0).flags_no_depth_test = false
	pass


remotesync func add_knockback(direction:Vector3):
	if (is_network_master()):
		knockback = direction*JUMP_FORCE
	pass


