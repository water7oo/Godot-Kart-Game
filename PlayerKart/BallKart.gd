extends Node3D


# Node references
@onready var ball = $Ball
@onready var car_mesh = $Kart
@onready var ground_ray = $isOnGround/GroundDetection4
# mesh references
@onready var right_wheel = $Kart/FrontRight
@onready var left_wheel = $Kart/FrontLeft
@onready var body_mesh = $Kart/Body

# Where to place the car mesh relative to the sphere
var sphere_offset = Vector3(0, -1.0, 0)
# Engine power
var acceleration = 5
# Turn amount, in degrees
var steering = 21.0
# How quickly the car turns
var turn_speed = 100
# Below this speed, the car doesn't turn
var turn_stop_limit = 0

# Variables for input values
var speed_input = 0
var rotate_input = 0

func _ready():
	ground_ray.add_exception(ball)
#	DebugOverlay.stats.add_property(ball, "linear_velocity", "length")
#	DebugOverlay.draw.add_vector(ball, "linear_velocity", 1, 4, Color(0, 1, 0, 0.5))
#	DebugOverlay.draw.add_vector(car_mesh, "transform:basis:z", -4, 4, Color(1, 0, 0, 0.5))

func _process(delta):
	print(ground_ray.is_colliding())
	# Can't steer/accelerate when in the air
	if not ground_ray.is_colliding():
		return
	# Get accelerate/brake input
	speed_input = 0
	speed_input += Input.get_action_strength("move_gas")
	speed_input -= Input.get_action_strength("move_brake")
	speed_input *= acceleration
	# Get steering input
	rotate_input = 0
	rotate_input += Input.get_action_strength('move_left')
	rotate_input -= Input.get_action_strength("move_right")
	rotate_input *= deg_to_rad(steering)
	
func _physics_process(delta):
	# Keep the car mesh aligned with the sphere
	car_mesh.transform.origin = ball.transform.origin + sphere_offset
	# Accelerate based on car's forward direction
	ball.apply_central_force(car_mesh.global_transform.basis.z * speed_input)

func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform
