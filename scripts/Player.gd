extends CharacterBody3D

# ~+'^'+~ CONTROLS ~+'^'+~ #
const IN_JUMP = "move_jump"
const IN_BACKWARD = "move_backward"
const IN_FORWARD = "move_forward"
const IN_LEFT = "move_left"
const IN_RIGHT = "move_right"
const IN_LEAN_LEFT = "lean_left"
const IN_LEAN_RIGHT = "lean_right"
const IN_FIRE = "primary_fire"
const IN_ALT_FIRE = "alternate_fire"
const MOUSE_SENS_MOD: float = 0.005
# ~+'^'+~ CONSTS ~+'^'+~ #
const xz: Vector3 = Vector3(1,0,1)
const LEDGE_HEIGHT: float = 0.55


var mouse_sens: float = 1.0

var speed: float = 5.0
const JUMP_VELOCITY: float = 4.5

# ~+'^'+~ HEURISTICS ~+'^'+~ #
var time_since_last_jump: float = 1
var distance_from_ground: float

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var cam: Camera3D = $PlayerCamera
@onready var body_view: SubViewport = $BodyContainer/BodyViewport
@onready var body_cam: Camera3D = $BodyContainer/BodyViewport/BodyCamera
@onready var pivot: Node3D = $Pivot
@onready var curb_ray: RayCast3D = $Pivot/CurbRay
@onready var ground_ray: RayCast3D = $GroundRay

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta):
	body_view.size = get_viewport().size + Vector2i(2,2) # ???
	body_cam.global_transform = cam.global_transform

func _physics_process(delta):
	Debug.print("Position", position)
	controls(delta)
	raycast_shit()
	#set_floor_snap_length(delta * lerp(0, 50, time_since_last_jump))
	#var was_on_floor: bool = is_on_floor()
	# TODO move and slide sucks ass
	move_and_slide()
	#if was_on_floor:
	#	apply_floor_snap()

func raycast_shit():
	ground_ray.force_raycast_update()
	if ground_ray.is_colliding():
		distance_from_ground = ground_ray.global_position.y - ground_ray.get_collision_point().y
	else:
		distance_from_ground = ground_ray.scale.y
	Debug.print("Velocity", velocity)
	Debug.print("Curb Ray Collision", "")
	Debug.print("Ledge Detection", "")
	Debug.print("Distance to Ground", distance_from_ground)
	
	# if moving, check for curb
	if (velocity * xz).length() > 0.01 and distance_from_ground < 0.4:
		pivot.look_at(pivot.global_position + velocity * xz)
		curb_ray.hit_back_faces = true # because weird geometry
		curb_ray.force_raycast_update()
		if curb_ray.is_colliding():
			var curb_height: float = curb_ray.get_collision_point().y - curb_ray.global_position.y + 2
			var curb_angle: float = curb_ray.get_collision_normal().angle_to(Vector3.UP)
			if curb_height < LEDGE_HEIGHT and curb_angle < floor_max_angle:
				var modifier: float = (floor_max_angle - curb_angle) / floor_max_angle
				Debug.print("Curb Ray Collision", modifier)
				position.y += curb_height * modifier
	# regardless, check for ledge
	pivot.look_at(pivot.global_position - transform.basis.z)
	curb_ray.hit_back_faces = false # because ceilings
	curb_ray.force_raycast_update()
	if curb_ray.is_colliding():
		var ledge_height: float = curb_ray.get_collision_point().y - curb_ray.global_position.y + 2
		if ledge_height > LEDGE_HEIGHT - 0.005:
			Debug.print("Ledge Detection", ledge_height)

func _input(event):
	if cam.current and event is InputEventMouseMotion and\
	Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sens * MOUSE_SENS_MOD)
		cam.rotate_x(-event.relative.y * mouse_sens * MOUSE_SENS_MOD)
		cam.rotation.x = clamp(cam.rotation.x, -PI*0.45, PI*0.45)

func controls(delta):
	if Input.is_action_just_pressed(IN_ALT_FIRE):
		pass # TODO
	
	# jump
	if not is_on_floor():
		velocity.y -= gravity * delta
	time_since_last_jump += delta
	if Input.is_action_just_pressed(IN_JUMP) and is_on_floor():
		velocity.y = JUMP_VELOCITY
		time_since_last_jump = 0
	# walk
	var input_dir = Input.get_vector(IN_LEFT, IN_RIGHT, IN_FORWARD, IN_BACKWARD)
	var dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if dir:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
