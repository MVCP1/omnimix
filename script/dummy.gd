extends KinematicBody


# Declare member variables here. Examples:
var life = 100

const JUMP_FORCE = 10
const GRAVITY = 0.98/2
const MAX_FALL_SPEED = 15

var y_vel = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("player")
	add_to_group("teamA")
	add_to_group("teamB")
	$Sprite3D.texture = $Sprite3D/Viewport.get_texture()
	pass # Replace with function body.

remotesync func damage(value):
	life = clamp(life-value, 0, 100)
	if life <= 0:
		life = 100
#	if not (is_network_master()):
#		$Healthbar.visible = true
	pass


func _physics_process(delta):
	$Sprite3D/Viewport/ProgressBar.value = life
	
	var move = Vector3()
	move.y = y_vel
	
	if move != Vector3(0,0,0):
		move_and_slide(move, Vector3(0, 1, 0))
	
	#GRAVITY
	y_vel -= GRAVITY
	#FALL SPEED LIMIT
	if y_vel < -MAX_FALL_SPEED:
		y_vel = -MAX_FALL_SPEED
	
	#HITTING A CEILING STOPS THE JUMP
	if (is_on_ceiling() and y_vel > 0) or is_on_floor():
		y_vel = 0
	pass
