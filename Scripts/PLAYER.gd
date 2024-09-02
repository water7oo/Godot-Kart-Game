extends VehicleBody3D
@onready var Camera = get_node("/root/Camera")

var camera = preload("res://PlayerKart/camera.tscn").instantiate()
var spring_arm_pivot = camera.get_node("SpringArmPivot")
var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")
var playerLook = camera.get_node("SpringArmPivot/MeshInstance3D")

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
@export var boost_timer = 1
var is_boosting = false
var boostDuration = 5
var max_rotation_z = 1
var max_rotation_x = 1

@export var mouse_sensitivity = .005
@export var joystick_sensitivity = .005
@export var cam_target : Node3D
@onready var mass_center_node = $CenterOfMass
@onready var speedDebug = $SpeedDebug
var can_jump = true
var isOnGround = false
var was_in_air = false
var drift_direction = 0
var counter_steer_strength = 20
var hopCount = 0
var driftRight = false
var driftLeft = false

# Drift parameters
var is_drifting: bool = false
var drift_progress: float = 0.0
var drift_duration: float = 5 # Time to fully drift (in seconds)

# Friction slip values
var normal_friction_slip_front: float = 10
var normal_friction_slip_back: float = 10.0
var drift_friction_slip_front: float = 0
var drift_friction_slip_back: float = 0.0

func _ready():
	pass # Replace with function body.


func _physics_process(delta):
	speedDebug.value = linear_velocity.length()
	_proccess_movement(delta)
	_process_drifting(delta)
	_proccess_boost(delta)
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
	#print((linear_velocity.z + linear_velocity.y + linear_velocity.x)/3)
	#print(linear_velocity.length())
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
	#if Input.is_action_just_pressed("move_drift") && isOnGround && hopCount == 0:
		#apply_central_impulse(Vector3(0,hopPower,0))
		#axis_lock_angular_z = true
		#was_in_air = true
		#isOnGround = false
		#hopCount = 1
		#print(hopCount)
	#else:
		#hopCount = 0
		#print(hopCount)
		
	if Input.is_action_pressed("move_drift") && isOnGround && Input.is_action_pressed("move_gas"):
		#await get_tree().create_timer(1).timeout
		
		if Input.is_action_pressed("move_left") && isOnGround:
			print("LEFT DRIFT")
			if driftRight:  
				drift_progress -= delta / drift_duration
			else:  
				drift_progress += delta / drift_duration
			is_drifting = true

		elif Input.is_action_pressed("move_right") && isOnGround:
			print("RIGHT DRIFT")
			if driftLeft:  
				drift_progress -= delta / drift_duration
			else:  
				drift_progress += delta / drift_duration
			is_drifting = true

		else:
			# If no direction input is pressed, stop drifting
			stop_drifting(delta)

		# Clamp drift progress between 0 and a reduced maximum value to prevent spinning out
		drift_progress = clamp(drift_progress, 0.0, 0.8) 

		# If we're drifting, maintain the drift steering value
		if drift_progress > 0.0:
			MAX_STEER = lerp(Initial_max_steer, DRIFT_STEER, drift_progress)
		else:
			# Keep the MAX_STEER at DRIFT_STEER if the drift is in progress
			MAX_STEER = DRIFT_STEER

		# Slightly increase rear wheel friction to prevent spin-out
		var rear_friction_boost = lerp(normal_friction_slip_back, drift_friction_slip_back * 12, drift_progress)
		Wheel3.wheel_friction_slip = rear_friction_boost
		Wheel4.wheel_friction_slip = rear_friction_boost

		# Interpolate X and Z velocity to 5 when drifting
		#linear_velocity.x = lerp(linear_velocity.x, 5, drift_progress)
		#linear_velocity.z = lerp(linear_velocity.z, 5, drift_progress)

	else:
		# Stop drifting if drift button or directional input is released
		stop_drifting(delta)

		# Interpolate X and Z velocity back to 0 when not drifting
		#linear_velocity.x = lerp(linear_velocity.x, 0, delta * 5.0)  # Adjust interpolation speed as needed
		#linear_velocity.z = lerp(linear_velocity.z, 0, delta * 5.0)  # Adjust interpolation speed as needed



func stop_drifting(delta):
	MAX_STEER = lerp(MAX_STEER, Initial_max_steer, delta * 5)  # Smooth transition back to normal steering
	drift_progress -= delta / drift_duration
	drift_progress = max(drift_progress, 0.0)
	is_drifting = false

	# Reset friction values
	Wheel1.wheel_friction_slip = normal_friction_slip_front
	Wheel2.wheel_friction_slip = normal_friction_slip_front
	Wheel3.wheel_friction_slip = normal_friction_slip_back
	Wheel4.wheel_friction_slip = normal_friction_slip_back
	physics_material_override.friction = 1


func _proccess_boost(delta):
	if Input.is_action_just_pressed("boost_debug") && !is_boosting:
		print("BOOSTING")
		boost_timer = boostDuration
		is_boosting = true
		MAX_SPEED = MAX_SPEED_BOOST
		ENGINE_POWER = BOOST_ENGINE_POWER
		
		if boost_timer <= 0:
			MAX_SPEED = Initial_max_speed
			boost_timer = 1
			ENGINE_POWER = Initial_engine_power
	if is_boosting:
			# Reduce the boost timer by delta time
			boost_timer -= delta
			var forward_direction = global_transform.basis.z
			apply_force(forward_direction.normalized() * boostPower)

			if boost_timer <= 0:
				# Stop boosting
				is_boosting = false
				MAX_SPEED = Initial_max_speed
				ENGINE_POWER = Initial_engine_power
				boost_timer = 0

	else:
		# Set to initial speed when not boosting
		MAX_SPEED = Initial_max_speed
		ENGINE_POWER = Initial_engine_power
