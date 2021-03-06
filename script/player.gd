extends KinematicBody

const SPEED = 10
const JUMP_FORCE = 10
const GRAVITY = 0.5#0.98/2
const MAX_FALL_SPEED = 25
 
var SENSITIVITY = -0.001
const ANGLE = 80
 
const AIR_CONTROL = 0.05
var RUNNING_MULTIPLIER = 1
const AIR_FRICTION = 0.5

var on_floor

var y_vel = 0
var inertia = Vector3()

var knockback = Vector3()

puppet var repl_position = Transform()

puppetsync var life = 100
puppetsync var defence = []

puppetsync var team = "N"

#POWER UP
puppetsync var power_up = 0
var power_up_duration = 2
var power_up_max = 0
var power_up_max_duration = 1
var power_up_delay = 0.2

#CONFIRMATION AND DURATION UI
var confirm = false
var duration = 1
var duration_value = 0
var charging = 0

var ammo = 0

puppetsync var seen = 0

puppetsync var stunned = 0


func _ready():
	add_to_group("player")
	randomize()
	$Healthbar.texture = $Healthbar/Viewport.get_texture()
	$Powerbar.texture = $Powerbar/Viewport.get_texture()
	$skin/outline.set_surface_material(0, $skin/outline.get_surface_material(0).duplicate())
	#HIDDING SELF SKIN
	if self.name == str(gamestate.player_info.net_id):
		get_node("skin").visible = false
	#HIDDING OTHER PLAYER'S INTERFACE
	if not (is_network_master()):
		$Camera/CanvasLayer/Control.visible = false
	#HIDE MOUSE CURSOR
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pass

func _input(event):
	if is_network_master() and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and stunned <= 0:
		#CAMERA ROTATION
		if event is InputEventMouseMotion:
			set_rotation(get_rotation() + Vector3(0,event.relative.x * SENSITIVITY, 0))
			get_node("Camera").set_rotation(get_node("Camera").get_rotation() + Vector3(event.relative.y * SENSITIVITY, 0, 0))
			get_node("Camera").set_rotation(Vector3(deg2rad(clamp(rad2deg(get_node("Camera").get_rotation().x), -ANGLE, ANGLE)), get_node("Camera").get_rotation().y, get_node("Camera").get_rotation().z))

func set_dominant_color(color):
	var material = SpatialMaterial.new()
	material.albedo_color = color
	$icon.material = material
	$skin.material_override = material




remotesync func damage(value):
	if (is_network_master()):
		var result = value
		for d in defence:
			result = result*d[0]
		rset("life", clamp(life-result, 0, 100))
		if life <= 0:
			rpc("die")
	if not (is_network_master()):
		$Healthbar.visible = true
	pass

remotesync func heal(value):
	if (is_network_master()):
		rset("life", clamp(life+value, 0, 100))
	if not (is_network_master()):
		$Healthbar.visible = true
	pass

remotesync func power_up(value):
	if (is_network_master()):
		rset("power_up", clamp(power_up+value, 0, 100))
		if power_up >= 100:
			power_up_max = power_up_max_duration
		else:
			power_up_max = power_up_delay
	pass

remotesync func defend(value, time, giver):
	if (is_network_master()):
		var has = false
		for d in defence:
			if not has:
				if d[2] == giver:
					d[1] = time
					has = true
		if not has:
			defence.append([value, time, giver])
		rset("defence", defence)


remotesync func die():
	match team:
		"A":
			translation = get_parent().get_node("SpawnPoints").get_node("TeamA").get_node(str(randi() % 5 + 1)).global_transform.origin
		"B":
			translation = get_parent().get_node("SpawnPoints").get_node("TeamB").get_node(str(randi() % 5 + 1)).global_transform.origin
		_:
			team = "A"
			translation = get_parent().get_node("SpawnPoints").get_node("TeamA").get_node(str(randi() % 5 + 1)).global_transform.origin
	RUNNING_MULTIPLIER = 1
	rpc("heal", 200)





remotesync func add_powers(choice):
	if $Camera.has_node("Power"):
		if $Camera.get_node("Power").filename != ("res://scenes/powers/" + choice + "/" + choice + ".tscn"):
			$Camera.get_node("Power").free()
			$Camera.add_child(load("res://scenes/powers/" + choice + "/" + choice + ".tscn").instance())
	else:
		$Camera.add_child(load("res://scenes/powers/" + choice + "/" + choice + ".tscn").instance())
	if (is_network_master()):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	RUNNING_MULTIPLIER = 1
	pass


remotesync func add_knockback(direction:Vector3):
	if (is_network_master()):
		knockback = direction*JUMP_FORCE
	pass


remotesync func see(time):
	if (is_network_master()):
		if time > seen:
			rset("seen", time)
	pass
	

func being_seen():
	if seen > 0:
		var player = get_tree().current_scene.get_node(str(gamestate.player_info.net_id))
		if team != player.team:
			$skin/outline.get_surface_material(0).flags_no_depth_test = not get_tree().current_scene.get_node(str(gamestate.player_info.net_id)).get_node("Camera").get_node("Test").can_see(self)
	else:
		$skin/outline.get_surface_material(0).flags_no_depth_test = false
	pass

remotesync func stun(time):
	if (is_network_master()):
		if time > stunned:
			rset("stunned", time)
	pass


func _physics_process(delta):
	if (is_network_master()):
		$Camera/Test.set_collision_mask_bit(1, team == "B")
		$Camera/Test.set_collision_mask_bit(2, team == "A")
		
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			#SETS THE CURRENT CAMERA
			$Camera.set_current(true)
			
			#ESC KEY QUITS THE GAME
			if Input.is_action_just_pressed("esc"):
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				#get_tree().change_scene("res://scenes/main_menu.tscn")
				get_tree().quit()
			
			#CHANGE POWERS
			if Input.is_action_just_pressed("h"):
				rpc("damage", 200)
				var choice = load("res://scenes/choice.tscn").instance()
				add_child(choice)
			#SUICIDE
			if Input.is_action_just_pressed("k"):
				stun(1)
				rpc("damage", 20)
			#CHANGE TEAM
			if Input.is_action_just_pressed("t"):
				match team:
					"A":
						team = "B"
					"B":
						team = "A"
					_:
						team = "A"
			
			#DEFENCE TIMER
			for d in defence:
				d[1] = d[1] - delta
				if d[1] <= 0:
					defence.erase(d)
			
			
			#FLOOR CHECK
			get_node("RayCast_floor").force_raycast_update()
			on_floor = is_on_floor() or get_node("RayCast_floor").is_colliding()
			
			#MOVEMENT VECTOR
			var move = Vector3()
			
			if stunned <= 0:
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
			move *= RUNNING_MULTIPLIER
			
			#ADDING GRAVITY
			if knockback.y > 1:
				y_vel = knockback.y
				knockback.y -= GRAVITY
			
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
			if knockback == Vector3(0,0,0):
				if not on_floor:
					move_and_slide(Vector3(inertia.x,move.y,inertia.z), Vector3(0, 1, 0), true)
				else:
					move_and_slide(move, Vector3(0, 1, 0), true)
			else:
				if not on_floor:
					move_and_slide(Vector3(inertia.x*0.5+knockback.x,move.y,inertia.z*0.5+knockback.z), Vector3(0, 1, 0), true)
				else:
					move_and_slide(Vector3(move.x*0.5+knockback.x,move.y,move.z*0.5+knockback.z), Vector3(0, 1, 0), true)
			
			
			
			#HITTING A CEILING STOPS THE JUMP
			if is_on_ceiling() and y_vel > 0:
				y_vel = 0
				knockback.y = 0
			
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
			
			
			#GRAVITY
			y_vel -= GRAVITY
			var just_jumped = false
			#JUMP
			if on_floor and Input.is_action_just_pressed("space") and stunned <= 0:
				just_jumped = true
				y_vel = JUMP_FORCE
			#CONSTANT GRAVITY WHEN ON FLOOR (FOR WALKING DOWN SLOPES)
			if on_floor and y_vel <= 0:
				y_vel = -4
			#FALL SPEED LIMIT
			if y_vel < -MAX_FALL_SPEED:
				y_vel = -MAX_FALL_SPEED
			
			
			
		#INTERFACE INFORMATION
			#POWERS
			if $Camera.has_node("Power"):
				$Camera/CanvasLayer/Control/Shift.value = ($Camera/Power.S*100)/$Camera/Power.waitS
				$Camera/CanvasLayer/Control/E.value = ($Camera/Power.E*100)/$Camera/Power.waitE
				$Camera/CanvasLayer/Control/G.value = ($Camera/Power.G*100)/$Camera/Power.waitG
			else:
				$Camera/CanvasLayer/Control/enemy.visible = false
				$Camera/CanvasLayer/Control/charging_max.visible = false
				$Camera/CanvasLayer/Control/charging.scale = Vector2(0,0)
			#AMMO
			$Camera/CanvasLayer/Control/Ammunition/Ammo.text = str(ammo)
			#CONFIRM POWERS
			$Camera/CanvasLayer/Control/Confirm.visible = confirm
			#DURATION POWERS
			$Camera/CanvasLayer/Control/Duration.visible = duration_value > 0
			$Camera/CanvasLayer/Control/Duration.value = duration_value
			duration_value = clamp(duration_value - (100*delta/duration), 0, 100)
			#POWER UP
			$Camera/CanvasLayer/Control/Power_Up.visible = power_up > 0
			$Camera/CanvasLayer/Control/Power_Up.value = power_up
			if power_up_max <= 0:
				power_up = clamp(power_up - (100*delta/power_up_duration), 0, 100)
				#rset("power_up", clamp(power_up - (100*delta/power_up_duration), 0, 100))
			else:
				power_up_max = clamp(power_up_max - delta, 0, 100)
			#DEFENCES
			var defs = ""
			for d in defence:
				defs = defs + str(d[0]) + "x" + " "
			$Camera/CanvasLayer/Control/Defences.text = defs
			
			
			#BEING SEEN TIME
			if seen > 0:
				seen -= delta
			if seen < 0:
				seen = 0
				#rset("seen", clamp(seen - delta, 0))
			
			#BEING STUNNED TIME
			if stunned > 0:
				stunned -= delta
			if stunned < 0:
				stunned = 0
			$Camera/CanvasLayer/Control/Stunned.visible = stunned > 0
			
			#POINT LOCATION
			if not $Camera.is_position_behind(get_parent().get_node("Desert").get_node("Point").get_node("Icon").global_transform.origin):
				$Camera/CanvasLayer/Control/point.position = $Camera.unproject_position(get_parent().get_node("Desert").get_node("Point").get_node("Icon").global_transform.origin)
			$Camera/CanvasLayer/Control/point.visible = not $Camera.is_position_behind(get_parent().get_node("Desert").get_node("Point").get_node("Icon").global_transform.origin)
			
			
			
		#DEBUG INFORMATION
			#MOVEMENT VECTOR
			$Camera/CanvasLayer/Control/RichTextLabel3.text = String(move)
			#INERTIA VECTOR
			$Camera/CanvasLayer/Control/RichTextLabel7.text = String(inertia)
			#LIFE INFORMATION
			$Camera/CanvasLayer/Control/ProgressBar.value = life
			#ON FLOOR (3x)
			if is_on_floor():
				$Camera/CanvasLayer/Control/Sprite3.set_modulate(Color(0,1,0,1))
			else:
				$Camera/CanvasLayer/Control/Sprite3.set_modulate(Color(1,0,0,1))
			if get_node("RayCast_floor").is_colliding():
				$Camera/CanvasLayer/Control/Sprite5.set_modulate(Color(0,1,0,1))
			else:
				$Camera/CanvasLayer/Control/Sprite5.set_modulate(Color(1,0,0,1))
			if on_floor:
				$Camera/CanvasLayer/Control/Sprite6.set_modulate(Color(0,1,0,1))
			else:
				$Camera/CanvasLayer/Control/Sprite6.set_modulate(Color(1,0,0,1))
			#ON CEILING
			if is_on_ceiling():
				$Camera/CanvasLayer/Control/Sprite4.set_modulate(Color(0,1,0,1))
			else:
				$Camera/CanvasLayer/Control/Sprite4.set_modulate(Color(1,0,0,1))
			#FALLING
			if !on_floor and y_vel < 0:
				$Camera/CanvasLayer/Control/Sprite2.set_modulate(Color(0,1,0,1))
			else:
				$Camera/CanvasLayer/Control/Sprite2.set_modulate(Color(1,0,0,1))
			#ON WALL
			if is_on_wall():
				$Camera/CanvasLayer/Control/Sprite7.set_modulate(Color(0,1,0,1))
			else:
				$Camera/CanvasLayer/Control/Sprite7.set_modulate(Color(1,0,0,1))
		
		
		
		
		####( !!!! REMEMBER FROM DOWN HERE EVERYTHING IS OUTSIDE THE IF MOUSE HIDDEN CONDITION !!!! )
		#### BUT ONLY IF THIS SCENE IS THE PLAYER OF THE CLIENT
		
		# Replicate the position
		rset("repl_position", transform)
	
		rset("life", life)
		rset("team", team)
		rset("power_up", power_up)
		rset("seen", seen)
		rset("stunned", stunned)
		rset("defence", defence)
	else:
		# THINGS HERE HAPPEN ONLY IF THIS SCENE ISN'T CONTROLLED BY THE CLIENT
		# Take replicated variables to set current actor state
		transform = repl_position
		$skin/outline.visible =  not get_tree().current_scene.get_node(str(gamestate.player_info.net_id)).team == team or defence.has([])
		$Healthbar/Viewport/Health.value = life
		$Powerbar/Viewport/Power_Up.value = power_up
		$Powerbar.visible = power_up > 0
		
	#INDEPENDENT PLAYER PROCESSES:
	####( !!!! REMEMBER FROM DOWN HERE EVERYTHING HAPPENS EVEN IF THIS PLAYER ISN'T CONTROLLED BY THE CLIENT !!!! )
	
	being_seen()
	
	
