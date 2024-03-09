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
var mouse_sens: float = 1.0
# ~+'^'+~ CONSTS ~+'^'+~ #
const X_Z: Vector3 = Vector3(1,0,1)
const LEDGE_HEIGHT: float = 0.55
const TERMINAL_VELOCITY: float = 60
const COYOTE_TIME: float = 0.2
const REVERSE_COYOTE_TIME: float = 0.1
# ~+'^'+~ HEURISTICS ~+'^'+~ #
var time_since_last_jump: float = 1
var coyote_timer: float = COYOTE_TIME + 1
var reverse_coyote_timer: float = COYOTE_TIME + 1
var distance_from_ground: float
var stepped_over_curb: bool = false
var cam_shock_absorber: float = 13

const JUMP_HEIGHT: float = 1.52
const JUMP_TIME: float = 0.35
const JUMP_FALL_TIME: float = 0.33

const JUMP_VELOCITY: float = 2 * JUMP_HEIGHT / JUMP_TIME
const JUMP_GRAVITY: float = 2 * JUMP_HEIGHT / JUMP_TIME**2
const FALL_GRAVITY: float = 2 * JUMP_HEIGHT / JUMP_FALL_TIME**2

const HEAD_Y: float = 1.5
const CAM_Y: float = 1.565
const MOVE_SPEED: float = 5.0
const ACCEL: float = 80.0

@onready var cam: Camera3D = $PlayerCamera
@onready var head: Area3D = $Head
@onready var arms: Node3D = $PlayerCamera/Arms
@onready var body_view: SubViewport = $BodyContainer/BodyViewport
@onready var body_cam: Camera3D = $BodyContainer/BodyViewport/BodyCamera
@onready var pivot: Node3D = $Pivot
@onready var ground_ray: RayCast3D = $GroundRay

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta):
	body_view.size = get_viewport().size + Vector2i(2,2) # ???
	arms.rotation.x = cam.rotation.x - lerp(0.0, cam.rotation.x, 0.42)
	body_cam.global_transform = cam.global_transform

func _physics_process(delta):
	var position_delta: Vector3 = position
	controls(delta)
	raycast_shit()
	move_and_slide()
	# duck
	var overlapping: Array = head.get_overlapping_bodies()
	overlapping.erase(self)
	Debug.print("Objs", overlapping)
	# TODO sometimes thinks it's not colliding when it is
	# TODO variable height crouch
	if overlapping.size() > 0:
		head.position.y = HEAD_Y - 0.53
	else:
		head.position.y = HEAD_Y
	position_delta =  position - position_delta
	cam.position.y -= position_delta.y
	cam.position.y = lerp(cam.position.y, head.position.y, delta * cam_shock_absorber)
	head.position.y = HEAD_Y

func get_gravity():
	return JUMP_GRAVITY if velocity.y > 0 else FALL_GRAVITY

func raycast_shit():
	ground_ray.force_raycast_update()
	if ground_ray.is_colliding():
		distance_from_ground = ground_ray.global_position.y - ground_ray.get_collision_point().y
	else:
		distance_from_ground = ground_ray.scale.y
	# if moving, check for curb
	stepped_over_curb = false
	if (velocity * X_Z).length() > 0.01 and distance_from_ground < 0.4:
		pivot.look_at(pivot.global_position + velocity * X_Z)
		for ray in pivot.get_children():
			ray.force_raycast_update()
			if ray.is_colliding():
				var curb_height: float = ray.get_collision_point().y - ray.global_position.y + ray.scale.y
				var curb_angle: float = ray.get_collision_normal().angle_to(Vector3.UP)
				if curb_height < LEDGE_HEIGHT and curb_angle < floor_max_angle:
					var angle_modifier: float = (floor_max_angle - curb_angle) / floor_max_angle
					position.y += curb_height * angle_modifier**2
					stepped_over_curb = true
	# regardless, check for ledge
	# TODO ledge rays need to be separate rays
	pivot.look_at(pivot.global_position - transform.basis.z)
	for ray in pivot.get_children():
		ray.force_raycast_update()
		if ray.is_colliding():
			var ledge_height: float = ray.get_collision_point().y - ray.global_position.y + ray.scale.y
			if ledge_height > LEDGE_HEIGHT - 0.005:
				Debug.print("Ledge", ledge_height)

func _input(event):
	if cam.current and event is InputEventMouseMotion and\
	Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sens * MOUSE_SENS_MOD)
		cam.rotate_x(-event.relative.y * mouse_sens * MOUSE_SENS_MOD)
		cam.rotation.x = clamp(cam.rotation.x, -PI*0.42, PI*0.44)

func controls(delta):
	# debug reset
	if Input.is_physical_key_pressed(KEY_R):
		position = Vector3.ZERO
		velocity = Vector3.ZERO
	# jump/fall
	var can_jump: bool = is_on_floor()
	coyote_timer += delta
	reverse_coyote_timer += delta
	if can_jump:
		coyote_timer = 0
	elif coyote_timer < COYOTE_TIME:
		can_jump = true
	time_since_last_jump += delta
	if Input.is_action_just_pressed(IN_JUMP) or\
	can_jump and reverse_coyote_timer < REVERSE_COYOTE_TIME:
		if can_jump:
			reverse_coyote_timer = REVERSE_COYOTE_TIME + 1
			coyote_timer = COYOTE_TIME + 1
			velocity.y = JUMP_VELOCITY
			time_since_last_jump = 0
		else:
			reverse_coyote_timer = 0
	else:
		velocity.y -= get_gravity() * delta
	# walk
	var input_dir = Input.get_vector(IN_LEFT, IN_RIGHT, IN_FORWARD, IN_BACKWARD)
	var dir = transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	var accel_modifier: float = 0.4 + 0.6 * dir.length()
	velocity.x = move_toward(velocity.x, dir.x * MOVE_SPEED, delta * ACCEL * accel_modifier)
	velocity.z = move_toward(velocity.z, dir.z * MOVE_SPEED, delta * ACCEL * accel_modifier)
