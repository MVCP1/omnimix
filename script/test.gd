extends RayCast

var body = []
var point = []
var normal = []


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	add_exception(get_parent().get_parent())
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func make_test(limit:float = 100.0, spread:float = 0.0, amount:int = 1, vect:Vector3 = Vector3(0,0,-1)):
	var n = abs(amount)
	var direction = vect.normalized()
	var hit = false
	body.clear()
	point.clear()
	normal.clear()
	while n > 0:
		n -= 1
#		cast_to = Vector3(nextGaussian3(0, 0.3, -1, 1)*spread, nextGaussian3(0, 0.3, -1, 1)*spread, (-1)*limit)
		cast_to = Vector3(nextGaussian3(0, 0.3, -1, 1)*spread*(1-abs(direction.x)), nextGaussian3(0, 0.3, -1, 1)*spread*(1-abs(direction.y)), nextGaussian3(0, 0.3, -1, 1)*spread*(1-abs(direction.z))) + direction*limit
		get_node("Limit").translation = cast_to
		force_raycast_update()
		if is_colliding():
			hit = true
			body.append(get_collider())
			point.append(get_collision_point())
			normal.append(get_collision_normal())
		else:
			body.append(null)
			point.append(get_node("Limit").global_transform.origin)
			normal.append(Vector3(0,0,0))
	return hit



func shotgun(limit:float = 50.0, radius:float = 1.0, amount:int = 1):
	print("YET TO BE IMPLEMENTED")
	pass




func can_see(who):
	var can = false
	look_at(who.global_transform.origin, Vector3(0,1,0))
	cast_to = Vector3(0,0,(-1)*global_transform.origin.distance_to(who.global_transform.origin))
	force_raycast_update()
	if is_colliding():
		if get_collider() == who:
			can = true
	rotation = Vector3(0,0,0)
	return can


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
