extends VehicleBody3D

var camera = preload("res://PlayerKart/camera.tscn").instantiate()
var spring_arm_pivot = camera.get_node("SpringArmPivot")
var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")
var playerLook = camera.get_node("SpringArmPivot/MeshInstance3D")
@onready var groundDetection1 = $GroundDetection
@onready var groundDetection2 = $GroundDetection2
@onready var groundDetection3 = $GroundDetection3
@onready var groundDetection4 = $GroundDetection4

@onready var Wheel1 = $VehicleWheel3D
@onready var Wheel2 = $VehicleWheel3D2
@onready var Wheel3 = $VehicleWheel3D3
@onready var Wheel4 = $VehicleWheel3D4

@export var Initial_max_steer = 0.4
@export var MAX_STEER = 0.4
@export var MAX_SPEED = 50
@export var DRIFT_STEER = 0.9
@export var ENGINE_POWER = 100
@export var hopPower = 100
@export var gravity = 20
@export var torquePower = 100
var max_rotation_z = 1
var max_rotation_x = 1

@export var mouse_sensitivity = .005
@export var joystick_sensitivity = .005
@export var cam_target : Node3D
@onready var mass_center_node = $CenterOfMass
@onready var speedDebug = $SpeedDebug
var can_jump = true
var isOnGround = false

# Drift parameters
var is_drifting: bool = false
var drift_progress: float = 0.0
var drift_duration: float = 2 # Time to fully drift (in seconds)

# Friction slip values
var normal_friction_slip: float = 300.0
var drift_friction_slip: float = 10.0


func _ready():
	speedDebug.value = linear_velocity.z
	pass # Replace with function body.


func _physics_process(delta):
	
	_proccess_movement(delta)
	_proccess_drifting(delta)
	rotationLimit(delta)

func rotationLimit(delta):
	var rotation = rotation_degrees

	# Adjust for wraparound and clamp the z-axis (roll) rotation
	if rotation.z > 180:
		rotation.z -= 360
		rotation.z = clamp(rotation.z, -max_rotation_z, max_rotation_z)

	# Adjust for wraparound and clamp the x-axis (pitch) rotation
	if rotation.x > 180:
		rotation.x -= 360
		rotation.x = clamp(rotation.x, -max_rotation_x, max_rotation_x)

	rotation_degrees = rotation
	
	
	if groundDetection1.is_colliding() && groundDetection2.is_colliding() && groundDetection3.is_colliding() && groundDetection4.is_colliding():
		#print("Kart is on Ground")
		isOnGround = true
		
func _proccess_movement(delta):
	#print((linear_velocity.z + linear_velocity.y + linear_velocity.x)/3)
	print(linear_velocity.length())
	var right_input = Input.get_action_strength("move_right")
	var left_input = Input.get_action_strength("move_left")

	var steering =  left_input - right_input
	steering = clamp(steering, -MAX_STEER, MAX_STEER)
	
	set_steering(steering * MAX_STEER)
	
	var engine_force = Input.get_axis("move_brake", "move_gas") * ENGINE_POWER 
	
	var current_speed = linear_velocity.length()
	
	if current_speed > MAX_SPEED:
		linear_velocity = linear_velocity.normalized() * MAX_SPEED
		#print("REDUCE SPEED")
	
	set_engine_force(engine_force)
	set_brake(Input.get_action_strength("move_brake") * ENGINE_POWER)
		
	
	
	

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit_game"):
		get_tree().quit()
		
	
	


func _proccess_drifting(delta):
	#if Input.is_action_just_pressed("move_drift") && groundDetection1.is_colliding():
		#apply_central_impulse(Vector3(0,hopPower,0))
		#axis_lock_angular_z = true
		#print("Drift Hop")
	
	#print(Wheel1.wheel_friction_slip)
	if Input.is_action_pressed("move_drift") && isOnGround && linear_velocity.length() >= 20:
		print("drift initiate")
		is_drifting = true
		
		
		if Input.is_action_pressed("move_left") && isOnGround:
			MAX_STEER = DRIFT_STEER
			drift_progress += delta / drift_duration
			drift_progress = min(drift_progress, 1.0)
			apply_torque_impulse(Vector3(0, torquePower, 0))
			print("Drifting Left")
		
		if Input.is_action_pressed("move_right") && isOnGround:
			MAX_STEER = DRIFT_STEER
			drift_progress += delta / drift_duration
			drift_progress = min(drift_progress, 1.0)
			apply_torque_impulse(Vector3(0, -torquePower, 0))
			print("Drifting Right")
	else:
		MAX_STEER = Initial_max_steer
		drift_progress -= delta / drift_duration
		drift_progress = max(drift_progress, 0.0)
		is_drifting = false
		
		Wheel1.wheel_friction_slip = 300
		Wheel2.wheel_friction_slip = 300
		Wheel3.wheel_friction_slip = 300
		Wheel4.wheel_friction_slip = 300
		physics_material_override.friction = 1
		
		
	var target_friction_slip = lerp(normal_friction_slip, drift_friction_slip, drift_progress)
	Wheel1.wheel_friction_slip = target_friction_slip
	Wheel2.wheel_friction_slip = target_friction_slip
	Wheel3.wheel_friction_slip = target_friction_slip
	Wheel4.wheel_friction_slip = target_friction_slip
	# Optionally interpolate material friction if needed
	physics_material_override.friction = lerp(1.0, 0.0, drift_progress)
		


