extends CharacterBody3D

# ~+'^'+~ CONTROLS ~+'^'+~ #
const IN_LEAN_LEFT = "lean_left"
const IN_LEAN_RIGHT = "lean_right"
const IN_FIRE = "primary_fire"
const IN_ALT_FIRE = "alternate_fire"
const MOUSE_SENS_MOD: float = 0.005
@export var mouse_sensitivity: float = 1.0
var input_dir: Vector3
# ~+'^'+~ CONSTS ~+'^'+~ #
const X_Z: Vector3 = Vector3(1,0,1)
const LEDGE_HEIGHT: float = 0.55
const TERMINAL_VELOCITY: float = -60.0
const COYOTE_TIME: float = 0.2
const REVERSE_COYOTE_TIME: float = 0.1
# ~+'^'+~ HEURISTICS ~+'^'+~ #
var time_since_last_jump: float = 1.0
var coyote_timer: float = COYOTE_TIME + 1.0
var reverse_coyote_timer: float = COYOTE_TIME + 1.0
var distance_from_ground: float
var grounded: bool = false
var posture: float = 1.0
var cam_raw_rotation: float = 0.0
var cam_y_velocity: float = 0.0
var arms_y_velocity: float = 0.0
# ~+'^'+~ CRAFTING THE PERFECT JUMP ~+'^'+~ #
const JUMP_HEIGHT: float = 1.3
const JUMP_TIME: float = 0.32
const FALL_TIME: float = 0.32
const JUMP_VELOCITY: float = 2 * JUMP_HEIGHT / JUMP_TIME
const JUMP_GRAVITY: float = 2 * JUMP_HEIGHT / JUMP_TIME**2
const FALL_GRAVITY: float = 2 * JUMP_HEIGHT / FALL_TIME**2
var HANG_TIME: float = 0.08
var hang_timer: float = HANG_TIME + 1

const HEAD_Y: float = 1.0
const CAM_Y: float = 1.565
const BASE_MOVE_SPEED: float = 4.2
const ACCEL: float = 16.0

var crouched: bool = false

@onready var cam: Camera3D = $PlayerCamera
@onready var head: Node3D = $Head
@onready var head_shape: ShapeCast3D = $Head/ShapeCast3D
@onready var arms: Node3D = $PlayerCamera/Arms
@onready var body_view: SubViewport = $BodyContainer/BodyViewport
@onready var body_cam: Camera3D = $BodyContainer/BodyViewport/BodyCamera
@onready var curb_rays: RayGroup = $CurbRays
@onready var ground_rays: RayGroup = $GroundRays

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# try to avoid angles between ~60° and ~75°
	floor_max_angle = deg_to_rad(65.0)
	floor_snap_length = 0.25

func _process(_delta):
	body_view.size = get_viewport().size + Vector2i(2,2) # doesn't render fully otherwise
	arms.rotation.x = cam.rotation.x - lerp(0.0, cam.rotation.x, 0.75)
	body_cam.global_transform = cam.global_transform

func _physics_process(delta):
	Debug.log("Vel", velocity)
	var position_delta: Vector3 = position
	controls(delta)
	raycast_shit()
	move_and_slide()
	# duck
	head_shape.force_shapecast_update()
	posture = head_shape.get_closest_collision_safe_fraction()
	var diff = posture * head_shape.target_position.y
	position_delta =  position - position_delta
	# smooth and bouncy camera
	cam.position.y -= position_delta.y
	var cam_stiffness: float = 18 if grounded else 25
	var cam_springyness: float = 140
	cam_y_velocity += (HEAD_Y + diff - cam.position.y) * delta * cam_springyness
	cam_y_velocity = clamp(cam_y_velocity, -30, 20)
	cam.position.y += cam_y_velocity * delta
	cam.position.y = lerp(cam.position.y, HEAD_Y + diff, delta * cam_stiffness)
	arms.position.y -= cam_y_velocity * delta * 0.35
	arms.position.y = lerp(arms.position.y, -0.4, delta * cam_stiffness)
	# head bob
	if grounded:
		var speed = (velocity * X_Z).length()**0.6
		cam.position.y += speed * 0.0013 * sin(Time.get_ticks_msec() * speed * 0.004)
		arms.position.y += speed * 0.0005 * sin(Time.get_ticks_msec() * speed * 0.004)
	

func get_gravity(delta):
	if velocity.y > 0:
		hang_timer = 0.0
		return JUMP_GRAVITY
	elif hang_timer < HANG_TIME:
		hang_timer += delta
		velocity.y = 0.0
		return 0.0
	return FALL_GRAVITY

func raycast_shit():
	ground_rays.fire_all()
	distance_from_ground = -RayGroup.dist(ground_rays.shortest_ray()).y
	# curb check
	if (velocity * X_Z).length() > 0.01 and distance_from_ground < 0.6:
		curb_rays.look_at(curb_rays.global_position + velocity * X_Z)
		curb_rays.fire_all()
		var short_ray: RayCast3D = curb_rays.shortest_ray()
		if short_ray != null:
			var curb_height: float = RayGroup.dist(short_ray).y - curb_rays.target_offset.y
			var curb_angle: float = RayGroup.angle(short_ray, Vector3.UP)
			if curb_height < LEDGE_HEIGHT and curb_angle < floor_max_angle:
				var angle_mod: float = (floor_max_angle - curb_angle) / floor_max_angle
				position.y += curb_height * angle_mod**2
	# regardless, check for ledge
	# TODO ledge rays need to be separate rays
	# curb_rays.look_at(curb_rays.global_position - transform.basis.z)
	# for ray in curb_rays.get_children():
	# 	ray.force_raycast_update()
	# 	if ray.is_colliding():
	# 		var ledge_height: float = ray.get_collision_point().y - ray.global_position.y + ray.scale.y
	# 		if ledge_height > LEDGE_HEIGHT - 0.005:

func _input(event):
	if cam.current and event is InputEventMouseMotion and\
	Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity * MOUSE_SENS_MOD)
		cam_raw_rotation -= event.relative.y * mouse_sensitivity * MOUSE_SENS_MOD
		cam_raw_rotation = clamp(cam_raw_rotation, -PI*0.42, PI*0.44)
		cam.rotation.x = cam_raw_rotation

func controls(delta):
	# debug reset
	if Input.is_action_just_pressed("reload"):
		position = Vector3.UP * 10
		velocity = Vector3.ZERO
	if Input.is_action_just_pressed("crouch"):
		crouched = not crouched
		head_shape.target_position.y = 0.0 if crouched else 0.5
	# am on ground?
	grounded = is_on_floor()
	# coyote -> wants to jump and had ground a moment ago
	# reverse coyote -> has ground and failed to jump a moment ago
	coyote_timer += delta
	reverse_coyote_timer += delta
	if grounded:
		coyote_timer = 0
	elif coyote_timer < COYOTE_TIME:
		grounded = true
	time_since_last_jump += delta
	if Input.is_action_just_pressed("move_jump") or\
	grounded and reverse_coyote_timer < REVERSE_COYOTE_TIME:
		if grounded:
			reverse_coyote_timer = REVERSE_COYOTE_TIME + 1
			coyote_timer = COYOTE_TIME + 1
			velocity.y = JUMP_VELOCITY
			time_since_last_jump = 0
		else: # pressed space, but not grounded
			reverse_coyote_timer = 0
	else:
		velocity.y -= get_gravity(delta) * delta
		velocity.y = max(velocity.y, TERMINAL_VELOCITY)
	# walk
	var input_xy: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	input_dir = transform.basis * Vector3(input_xy.x, 0, input_xy.y)
	var accel_mod: float = 0.4 + 0.6 * input_dir.length()
	if not grounded: # floating
		accel_mod *= 0.3
	var posture_mod = posture if grounded else 1.0
	var sprint_mod = 1.5 if Input.is_action_pressed("sprint") else 1.0
	var move_speed: float = BASE_MOVE_SPEED * (0.5 + 0.5 * posture_mod) * sprint_mod
	var target_vel: Vector3 = velocity * Vector3.UP + input_dir * move_speed
	velocity = velocity.move_toward(target_vel, delta * ACCEL * accel_mod * move_speed)
