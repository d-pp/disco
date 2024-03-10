extends Node3D
class_name RayGroup

@export var target_offset: Vector3

func _ready():
	for ray in get_children():
		if ray is RayCast3D:
			ray.scale = Vector3.ONE
			ray.target_position = target_offset

func fire_all() -> void:
	for ray in get_children():
		if ray is RayCast3D:
			ray.force_raycast_update()

func shortest_ray() -> RayCast3D:
	var min_ray: RayCast3D = null
	var min_length: float = INF
	for ray in get_children():
		if ray is RayCast3D and ray.is_colliding():
			var _length = (ray.get_collision_point() - ray.global_position).length()
			if _length < min_length:
				min_length = _length
				min_ray = ray
	return min_ray

static func dist(ray: RayCast3D) -> Vector3:
	if ray == null:
		return Vector3.INF
	return ray.get_collision_point() - ray.global_position

static func length(ray: RayCast3D) -> float:
	if ray == null:
		return INF
	return dist(ray).length()

static func angle(ray: RayCast3D, reference: Vector3 = Vector3.UP) -> float:
	if ray == null:
		return INF 
	return ray.get_collision_normal().angle_to(reference)
