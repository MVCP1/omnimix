extends KinematicBody

const SPEED = 8
const JUMP_FORCE = 10
const GRAVITY = 0.98/2
const MAX_FALL_SPEED = 15
 
const SENSITIVITY = -0.001
const ANGLE = 80
 
const AIR_CONTROL = 0.05
const RUNNING_MULTIPLIER = 1.5*8
const AIR_FRICTION = 0.5

var y_vel = 0
var inertia = Vector3()

puppet var repl_position = Transform()

puppet var life = 100


func _ready():
	add_to_group("player")
	randomize()
	$Healthbar.texture = $Healthbar/Viewport.get_texture()
	#HIDE MOUSE CURSOR
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pass

func _input(event):
	if (is_network_master()):
		#CAMERA ROTATION
		if event is InputEventMouseMotion:
			set_rotation(get_rotation() + Vector3(0,event.relative.x * SENSITIVITY, 0))
			get_node("Camera").set_rotation(get_node("Camera").get_rotation() + Vector3(event.relative.y * SENSITIVITY, 0, 0))
			get_node("Camera").set_rotation(Vector3(deg2rad(clamp(rad2deg(get_node("Camera").get_rotation().x), -ANGLE, ANGLE)), get_node("Camera").get_rotation().y, get_node("Camera").get_rotation().z))

func set_dominant_color(color):
	var material = SpatialMaterial.new()
	material.albedo_color = color
	$icon.material = material

remotesync func damage(value):
	life = life-value
	if not (is_network_master()):
		$Healthbar.visible = true
	pass

remotesync func shoot(who, loc, front, rot, parent):
	var bclass = load("res://scenes/bullet.tscn")
	var bactor = bclass.instance()
	bactor.dad = who
	bactor.global_translate(loc)
	bactor.front = front
	bactor.rotation = rot
	get_parent().add_child(bactor)
	pass

func _physics_process(delta):
	if (is_network_master()):
		$Camera/CanvasLayer.layer = 2
		
		#SETS THE CURRENT CAMERA
		$Camera.set_current(true)
		
		#ESC KEY QUITS THE GAME
		if Input.is_action_just_pressed("esc"):
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			#get_tree().change_scene("res://scenes/main_menu.tscn")
			get_tree().quit()
		
		#SUICIDE
		if Input.is_action_just_pressed("k"):
			rpc("damage", 200)
		
		#SHOOTS BULLET
		if Input.is_action_just_pressed("mouse_left"):
			rpc("shoot", name, $Camera.global_transform.origin, ($Camera/Position3D.global_transform.origin - $Camera.global_transform.origin).normalized(), rotation + Vector3(PI,0,0) + Vector3(0,0,$Camera.rotation.z), get_parent())
			$AudioStreamPlayer.play()
			pass
		#SHOOTS RAYCAST
		if Input.is_action_just_pressed("mouse_right"):
			$Camera/Test.force_raycast_update()
			if $Camera/Test.is_colliding():
				if $Camera/Test.get_collider().is_in_group("player"):
					$Camera/Test.get_collider().rpc("damage", 10)
				print($Camera/Test.get_collider())
				var eclass = load("res://scenes/explosion.tscn")
				var eactor = eclass.instance()
				eactor.global_translate($Camera/Test.get_collision_point())
				get_parent().add_child(eactor)
				$AudioStreamPlayer.play()
			pass
		
		#FLOOR CHECK
		get_node("RayCast_floor").force_raycast_update()
		var on_floor = is_on_floor() or get_node("RayCast_floor").is_colliding()
		
		#MOVEMENT VECTOR
		var move = Vector3()
		
		if Input.is_action_pressed("front"):
			move.z -= 1
		if Input.is_action_pressed("back"):
			move.z += 1
		if Input.is_action_pressed("right"):
			move.x += 1
		if Input.is_action_pressed("left"):
			move.x -= 1
		
		move = move.normalized()
		move = move.rotated(Vector3(0, 1, 0), rotation.y)
		move *= SPEED
		
		#RUNNING
		if Input.is_action_pressed("shift"):
			move *= RUNNING_MULTIPLIER
		
		#ADDING GRAVITY
		move.y = y_vel
		
		#CALCULATES INERTIA USING AIR FRICTION
		if (move.x != 0 or move.z != 0) and on_floor:
			inertia = move*(1-AIR_FRICTION)
		elif on_floor:
			inertia = Vector3(0,0,0)
		
		#AIR CONTROL ON INERTIA
		if (move.x != 0 or move.z != 0) and not on_floor:
			#INERTIA CAN'T BE BIGGER THAN MOVING SPEED
			if abs(inertia.x) < abs(move.x) or not inertia.x*move.x > 0:
				inertia.x += move.x*AIR_CONTROL
			if abs(inertia.z) < abs(move.z) or not inertia.z*move.z > 0:
				inertia.z += move.z*AIR_CONTROL
		
		#ACTUALLY MOVING
		if not on_floor:
			move_and_slide(Vector3(inertia.x,move.y,inertia.z), Vector3(0, 1, 0), true)
		else:
			move_and_slide(move, Vector3(0, 1, 0), true)
		
		
		#HITTING A CEILING STOPS THE JUMP
		if is_on_ceiling() and y_vel > 0:
			y_vel = 0
		
		#GRAVITY
		y_vel -= GRAVITY
		var just_jumped = false
		#JUMP
		if on_floor and Input.is_action_just_pressed("space"):
			just_jumped = true
			y_vel = JUMP_FORCE
		#CONSTANT GRAVITY WHEN ON FLOOR (FOR WALKING DOWN SLOPES)
		if on_floor and y_vel <= 0:
			y_vel = -4
		#FALL SPEED LIMIT
		if y_vel < -MAX_FALL_SPEED:
			y_vel = -MAX_FALL_SPEED
		
		
		
		
		
	#DEBUG INFORMATION
		#MOVEMENT VECTOR
		$Camera/CanvasLayer/RichTextLabel3.text = String(move)
		#INERTIA VECTOR
		$Camera/CanvasLayer/RichTextLabel7.text = String(inertia)
		#LIFE INFORMATION
		$Camera/CanvasLayer/ProgressBar.value = life
		#ON FLOOR (3x)
		if is_on_floor():
			$Camera/CanvasLayer/Sprite3.set_modulate(Color(0,1,0,1))
		else:
			$Camera/CanvasLayer/Sprite3.set_modulate(Color(1,0,0,1))
		if get_node("RayCast_floor").is_colliding():
			$Camera/CanvasLayer/Sprite5.set_modulate(Color(0,1,0,1))
		else:
			$Camera/CanvasLayer/Sprite5.set_modulate(Color(1,0,0,1))
		if on_floor:
			$Camera/CanvasLayer/Sprite6.set_modulate(Color(0,1,0,1))
		else:
			$Camera/CanvasLayer/Sprite6.set_modulate(Color(1,0,0,1))
		#ON CEILING
		if is_on_ceiling():
			$Camera/CanvasLayer/Sprite4.set_modulate(Color(0,1,0,1))
		else:
			$Camera/CanvasLayer/Sprite4.set_modulate(Color(1,0,0,1))
		#FALLING
		if !on_floor and y_vel < 0:
			$Camera/CanvasLayer/Sprite2.set_modulate(Color(0,1,0,1))
		else:
			$Camera/CanvasLayer/Sprite2.set_modulate(Color(1,0,0,1))
		#ON WALL
		if is_on_wall():
			$Camera/CanvasLayer/Sprite7.set_modulate(Color(0,1,0,1))
		else:
			$Camera/CanvasLayer/Sprite7.set_modulate(Color(1,0,0,1))
		#ENEMY INFORMATION
		if not $Camera.is_position_behind(get_parent().get_node("TestMap").get_node("Walls").get_node("KinematicBody").global_transform.origin):
			$Camera/CanvasLayer/enemy.position = $Camera.unproject_position(get_parent().get_node("TestMap").get_node("Walls").get_node("KinematicBody").global_transform.origin)
		$Camera/CanvasLayer/enemy.visible = not $Camera.is_position_behind(get_parent().get_node("TestMap").get_node("Walls").get_node("KinematicBody").global_transform.origin)
		
		# Replicate the position
		rset("repl_position", transform)
	
	else:
		# Take replicated variables to set current actor state
		transform = repl_position
	
	#INDEPENDENT PLAYER PROCESSES:
	
	#DYING
	if life <= 0:
		if is_in_group("teamA"):
			translation = get_parent().get_node("SpawnPoints").get_node("TeamA").get_node(str(randi() % 5 + 1)).global_transform.origin
		if is_in_group("teamB"):
			translation = get_parent().get_node("SpawnPoints").get_node("TeamB").get_node(str(randi() % 5 + 1)).global_transform.origin
		life = 100
	
	#SETTING LIFE
	if (get_tree().is_network_server()):
		rset("life", life)
	$Healthbar/Viewport/Health.value = life
