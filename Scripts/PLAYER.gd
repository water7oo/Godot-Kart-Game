extends VehicleBody3D

#@onready var autoloadCamera = get_node("/root/Camera")

var camera_preload = preload("res://PlayerKart/camera.tscn").instantiate()
var camera = camera_preload.get_node("SpringArmPivot/SpringArm3D/Camera3D")
var spring_arm_pivot = camera_preload.get_node("SpringArmPivot")
var spring_arm = camera_preload.get_node("SpringArmPivot/SpringArm3D")
var playerLook = camera_preload.get_node("SpringArmPivot/MeshInstance3D")

@onready var drift_dust = get_tree().get_nodes_in_group("drift_dust")


@onready var groundDetection1 = $isOnGround/GroundDetection
@onready var groundDetection2 = $isOnGround/GroundDetection2
@onready var groundDetection3 = $isOnGround/GroundDetection3
@onready var groundDetection4 = $isOnGround/GroundDetection4

@onready var Wheel1 = $VehicleWheel3D
@onready var Wheel2 = $VehicleWheel3D2
@onready var Wheel3 = $VehicleWheel3D3
@onready var Wheel4 = $VehicleWheel3D4

@export var Initial_max_steer = 0.1
@export var Initial_max_speed = 70
@export var MAX_STEER = 0.1
@export var MAX_SPEED = 50
@export var DRIFT_STEER = 1.5
@export var MAX_SPEED_BOOST = 100
@export var Initial_engine_power = 100
@export var BOOST_ENGINE_POWER = 200
@export var ENGINE_POWER = 100
@export var hopPower = 100
@export var gravity = 20
@export var torquePower = 100
@export var boostPower = 20
@export var boost_timer = 0.0
@export var speed_lerp_factor := 0.0 
@export var BOOST_SPEED_TRANSITION_RATE = 12
@export var BRAKE_FORCE = 10

@export var driftBoostTimer = 0.0
var is_boosting = false
var boostDuration = 1
var max_rotation_z = 1
var max_rotation_x = 1

var driftBoostTime = 0.0

@export var mouse_sensitivity = .005
@export var joystick_sensitivity = .005
@export var cam_target : Node3D
@onready var mass_center_node = $CenterOfMass
@export var speedDebug : Node
var can_jump = true
var isOnGround = false
var was_in_air = false
var drift_direction = 0
@export var counter_steer_strength = 1
var hopCount = 0
var driftRight = false
var driftLeft = false

@export var DRIFT_FORCE = 10
@export var DRIFT_INTERTIA = 9000
@export var MAX_DRIFT_ANGLE = 180


# Drift parameters
var is_drifting: bool = false
var drift_progress: float = 0.0
var drift_duration: float = 100 # Time to fully drift (in seconds)

# Friction slip values
var normal_friction_slip_front: float = 10
var normal_friction_slip_back: float = 9.5
var drift_friction_slip_front: float = 0
var drift_friction_slip_back: float = 0.0

var normal_fov = 20 # Normal FOV value
var boost_fov = 90 # FOV value when boosting
var fov_transition_speed = 1.0 # How quickly the FOV changes

func _ready():
	speedDebug = $SpeedDebug
	pass # Replace with function body.


func _physics_process(delta):
	print('Wheel back 3:' + str(Wheel3.wheel_friction_slip), 'Wheel back 4:' + str(Wheel4.wheel_friction_slip), 'Wheel back 1:' + str(Wheel1.wheel_friction_slip), 'Wheel back 2:' + str(Wheel2.wheel_friction_slip))
	print('MAX STEER' + str(MAX_STEER))
	
	if speedDebug != null:
		speedDebug.value = linear_velocity.length()
	else:
		print("speedDebug node is not initialized or found!")
		
		
	_proccess_movement(delta)
	_process_drifting(delta)
	#_proccess_boost(delta)
	
	#print("MAXIMUM SPEED: " + str(MAX_SPEED))
	#print("BOOST TIMER: " + str(boost_timer))
	#print(MAX_STEER)
	
	if Input.is_action_pressed("boost_debug") and !is_boosting and Input.is_action_pressed("move_gas"):
		apply_torque(Vector3(70,70,70))
		is_boosting = true
		boost_timer = boostDuration  # Initialize the boost timer
		_playerBoost(delta)
	elif is_boosting:
		_playerBoost(delta)
		
	
	rotationLimit(delta)
	particles(delta)

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
	var right_input = Input.get_action_strength("move_right")
	var left_input = Input.get_action_strength("move_left")

	var steering =  left_input - right_input
	steering = clamp(steering, -MAX_STEER, MAX_STEER)
	
	set_steering(steering * MAX_STEER)
	
	var engine_force = Input.get_axis("move_brake", "move_gas") * Initial_engine_power
	
	var current_speed = linear_velocity.length()
	
	
	if current_speed > MAX_SPEED:
		linear_velocity = linear_velocity.normalized() * MAX_SPEED
		#print("REDUCE SPEED")
	
	set_engine_force(engine_force)
	set_brake(Input.get_action_strength("move_brake") * ENGINE_POWER)
		
		
	#if Input.is_action_pressed("move_brake"):
		#Wheel1.use_as_traction = true
		#Wheel2.use_as_traction = true
	#else:
		#Wheel1.use_as_traction = false
		#Wheel2.use_as_traction = false
	

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit_game"):
		get_tree().quit()
		
	
	

func particles(delta):
	var particle_emitter1 = $DriftDust/GPUParticles3D
	var particle_emitter2 = $DriftDust2/GPUParticles3D
	
	
	if particle_emitter1 && particle_emitter2:
		if isOnGround && is_drifting:
			particle_emitter1.set_emitting(true)
			particle_emitter2.set_emitting(true)
				
		else:
			particle_emitter1.set_emitting(false)
			particle_emitter2.set_emitting(false)


func _process_drifting(delta):
	if Input.is_action_pressed("move_drift") and isOnGround and Input.is_action_pressed("move_gas"):
		driftBoostTimer += delta  # Start counting drift time
		#print("DRIFT BOOST TIMER: " + str(driftBoostTimer))

		# Determine direction based on player input
		var direction = Vector3(0, 0, 0)
		if Input.is_action_pressed("move_left") and isOnGround:
			direction = -transform.basis.x
			is_drifting = true
		elif Input.is_action_pressed("move_right") and isOnGround:
			direction = transform.basis.x  # Right drift direction
			is_drifting = true
		else:
			stop_drifting(delta)

		# Apply a gradual force in the direction of the drift
		if is_drifting:
			var drift_force = direction.normalized() * DRIFT_FORCE * delta
			apply_force(drift_force, Vector3(0, 1, 0))  # Apply force at the center of mass
			var DRIFT_INERTIA = 100

			# Apply inertia and angular velocity to simulate sliding
			var angular_velocity = rotation_degrees.y * delta * DRIFT_INERTIA
			angular_velocity = clamp(angular_velocity, -MAX_DRIFT_ANGLE, MAX_DRIFT_ANGLE)
			#angular_velocity_degrees.y += angular_velocity

			# Adjust friction based on drift progress
			drift_progress += delta / drift_duration
			drift_progress = clamp(drift_progress, 0.0, 1.0)
			
			var rear_friction = lerp(normal_friction_slip_back, drift_friction_slip_back, drift_progress)
			Wheel3.wheel_friction_slip = rear_friction
			Wheel4.wheel_friction_slip = rear_friction
			
			# Drift boost handling
			if Input.is_action_just_released("move_drift"):
				if driftBoostTimer >= 2:
					is_boosting = true  # Start the boost
					_playerBoost(delta)
			else:
				driftBoostTimer = 0.0  # Reset drift timer
	else:
		stop_drifting(delta)


func stop_drifting(delta):
	is_drifting = false
	drift_progress = 0.0

	# Reset friction values
	Wheel3.wheel_friction_slip = normal_friction_slip_back
	Wheel4.wheel_friction_slip = normal_friction_slip_back
	physics_material_override.friction = 1



func _playerBoost(delta):
	if is_boosting && isOnGround:
		boost_timer -= delta  # Decrease the boost timer
		MAX_SPEED = MAX_SPEED_BOOST
		ENGINE_POWER = BOOST_ENGINE_POWER
		camera.fov = boost_fov

		speed_lerp_factor = min(speed_lerp_factor + delta * BOOST_SPEED_TRANSITION_RATE, 1.0)
		var forward_direction = global_transform.basis.z.normalized()
		var target_speed = forward_direction * float(boostPower)
		linear_velocity = linear_velocity.lerp(target_speed, speed_lerp_factor)

		if linear_velocity.length() > Initial_max_speed:
			linear_velocity = linear_velocity.normalized() * min(linear_velocity.length(), MAX_SPEED)

		if boost_timer <= 0:
			_end_boost()
	else:
		MAX_SPEED = float(Initial_max_speed)


func _end_boost():
	is_boosting = false
	boost_timer = boostDuration
	MAX_SPEED = float(Initial_max_speed)
	ENGINE_POWER = float(Initial_engine_power)
	camera.fov = normal_fov

	if linear_velocity.length() > MAX_SPEED:
		linear_velocity = linear_velocity.normalized() * MAX_SPEED

	


