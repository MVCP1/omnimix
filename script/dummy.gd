extends KinematicBody


# Declare member variables here. Examples:
var life = 100

var power_up = 0
var power_up_duration = 2
var power_up_max = 0
var power_up_max_duration = 1
var power_up_delay = 0.2

const JUMP_FORCE = 10
const GRAVITY = 0.98/2
const MAX_FALL_SPEED = 15

var y_vel = 0

var seen = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("player")
	add_to_group("teamA")
	add_to_group("teamB")
	$Sprite3D.texture = $Sprite3D/Viewport.get_texture()
	$Sprite3D2.texture = $Sprite3D2/Viewport.get_texture()
	$skin/outline.set_surface_material(0, $skin/outline.get_surface_material(0).duplicate())
	pass # Replace with function body.

remotesync func damage(value):
	life = clamp(life-value, 0, 100)
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
	if (is_network_master()):
		if time > seen:
			seen = time
	pass

func _physics_process(delta):
	$Sprite3D/Viewport/ProgressBar.value = life
	
	$Sprite3D2.visible = power_up > 0
	$Sprite3D2/Viewport/ProgressBar.value = power_up
	if power_up_max <= 0:
		power_up = clamp(power_up - (100*delta/power_up_duration), 0, 100)
	else:
		power_up_max = clamp(power_up_max - delta, 0, 100)
	
	var move = Vector3()
	move.y = y_vel
	
	if move != Vector3(0,0,0):
		move_and_slide(move, Vector3(0, 1, 0))
	
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
	if (is_on_ceiling() and y_vel > 0) or is_on_floor():
		y_vel = 0
	pass

func being_seen():
	if seen > 0:
		$skin/outline.get_surface_material(0).flags_no_depth_test = not get_tree().current_scene.get_node(str(gamestate.player_info.net_id)).get_node("Camera").get_node("Test").can_see(self)
	else:
		$skin/outline.get_surface_material(0).flags_no_depth_test = false
	pass
