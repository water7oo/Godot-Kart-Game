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
@export var speed_lerp_factor := 0.000007
@export var BOOST_SPEED_TRANSITION_RATE = 12
@export var BRAKE_FORCE = 10

@export var driftBoostTimer = 0.0
var is_boosting = false
var boostDuration = 1
var max_rotation_z = 1
var max_rotation_x = 1

@export var driftBoostTime = 0.0

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
@export var target_speed_power = 200

var driftBoostSpark = 1

# Drift parameters
var is_drifting: bool = false
var drift_progress: float = 1.0
var drift_duration: float = 1000 # Time to fully drift (in seconds)


var is_drift_sparking1 = false
# Friction slip values
@export var normal_friction_slip_front: float = 10
@export var normal_friction_slip_back: float = 5
@export var drift_friction_slip_front: float = 0
@export var drift_friction_slip_back: float = 0.0

var normal_fov = 20 # Normal FOV value
var boost_fov = 90 # FOV value when boosting
var fov_transition_speed = 1.0 # How quickly the FOV changes

func _ready():
	speedDebug = $SpeedDebug
	pass # Replace with function body.


func _physics_process(delta):
	#print(drift_progress)
	#print('Wheel back 3:' + str(Wheel3.wheel_friction_slip), 'Wheel back 4:' + str(Wheel4.wheel_friction_slip), 'Wheel back 1:' + str(Wheel1.wheel_friction_slip), 'Wheel back 2:' + str(Wheel2.wheel_friction_slip))
	#print('MAX STEER' + str(MAX_STEER))
	boostSparking(delta)
	
	
	if speedDebug != null:
		speedDebug.value = linear_velocity.length()
	else:
		print("speedDebug node is not initialized or found!")
		
		
	_proccess_movement(delta)
	_process_drifting(delta)
	carSounds(delta)
	
	if Input.is_action_pressed("boost_debug") && !is_boosting && Input.is_action_pressed("move_gas"):
		is_boosting = true
		boost_timer = boostDuration  # Initialize the boost timer
		_playerBoost(delta)
	elif is_boosting:
		_playerBoost(delta)
		
	
	rotationLimit(delta)
	particles(delta)

func rotationLimit(delta):
	var rotation = rotation_degrees

	# Adjust for wraparound && clamp the z-axis (roll) rotation
	if rotation.z > 180:
		rotation.z -= 360
		rotation.z = clamp(rotation.z, -max_rotation_z, max_rotation_z)

	# Adjust for wraparound && clamp the x-axis (pitch) rotation
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
	#set_brake(Input.get_action_strength("move_brake") * 5000 * BRAKE_FORCE)
		
	#if Input.is_action_pressed("move_brake"):
		#ENGINE_POWER -= 50
		#Wheel1.use_as_traction = true
		#Wheel2.use_as_traction = true
	#else:
		#ENGINE_POWER = Initial_engine_power
		#Wheel1.use_as_traction = false
		#Wheel2.use_as_traction = false

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit_game"):
		get_tree().quit()
		
	
	

func carSounds(delta):
	if Input.is_action_pressed("move_gas") && linear_velocity.length() >= MAX_SPEED - 60:
			if not $AudioStreamPlayer.is_playing():
				$AudioStreamPlayer.play()  # Only play if it's not already playing
				print("VROOOOM")
	else:
		if $AudioStreamPlayer.is_playing():
			$AudioStreamPlayer.stop()  # Stop the sound when "move_gas" is released
		


func particles(delta):
	var particle_emitter1 = $DriftDust/GPUParticles3D
	var particle_emitter2 = $DriftDust2/GPUParticles3D
	
	#var DriftSparks1 = $DriftBoost1/GPUParticles3D
	#var DriftSparks2 = $DriftBoost2/GPUParticles3D
	
	if particle_emitter1 && particle_emitter2:
		if isOnGround && is_drifting:
			particle_emitter1.set_emitting(true)
			particle_emitter2.set_emitting(true)
				
		else:
			particle_emitter1.set_emitting(false)
			particle_emitter2.set_emitting(false)

	#if DriftSparks1 && DriftSparks2:
		#if isOnGround && is_drifting && is_drift_sparking1:
			#DriftSparks1.set_emitting(true)
			#DriftSparks2.set_emitting(true)
		#else:
			#DriftSparks1.set_emitting(false)
			#DriftSparks2.set_emitting(false)

func _process_drifting(delta):
	if Input.is_action_pressed("move_drift") and isOnGround and Input.is_action_pressed("move_gas") and linear_velocity.length() >= MAX_SPEED - 55:
		#await get_tree().create_timer(1).timeout
		driftBoostTimer += delta  # Start counting drift time
		driftBoostSpark -= delta

		var direction = Vector3.ZERO
		if Input.is_action_pressed("move_left") and isOnGround:
			direction = -transform.basis.x  # Left drift direction
			is_drifting = true
		elif Input.is_action_pressed("move_right") and isOnGround:
			direction = transform.basis.x  # Right drift direction
			is_drifting = true
		else:
			stop_drifting(delta)

		# Apply a gradual force in the direction of the drift
		if is_drifting and isOnGround:
			# Adjust friction progressively based on the duration of the drift
			drift_progress += delta / drift_duration
			drift_progress = clamp(drift_progress, 0.0, 1.0)

			# Play drift sound if not already playing
			if not $AudioStreamPlayer2.is_playing():
				$AudioStreamPlayer2.play()

			# Reduce rear friction gradually to simulate drifting/sliding
			var rear_friction = lerp(normal_friction_slip_back, drift_friction_slip_back, drift_progress)
			Wheel3.wheel_friction_slip = rear_friction
			Wheel4.wheel_friction_slip = rear_friction

			# Maintain current speed during drifting
			var forward_direction = global_transform.basis.z.normalized()
			var drift_direction = direction.normalized()
			var combined_direction = (forward_direction + drift_direction).normalized()

			var current_speed = linear_velocity.length()
			var target_speed = combined_direction * clamp(current_speed, MAX_SPEED - 10, MAX_SPEED)
			
			# Smoothly adjust the velocity to approach the target speed while drifting
			linear_velocity = linear_velocity.lerp(target_speed, speed_lerp_factor)

			# Apply additional force to maintain speed during the drift
			apply_central_impulse(forward_direction * DRIFT_FORCE)

	else:
		stop_drifting(delta)
		driftBoostSpark = 1

		# Stop the sound when drifting ends
		if $AudioStreamPlayer2.is_playing():
			$AudioStreamPlayer2.stop()
	
	if !isOnGround:
		stop_drifting(delta)



func stop_drifting(delta):
	is_drifting = false
	drift_progress = 0.0

	# Reset friction values
	Wheel3.wheel_friction_slip = normal_friction_slip_back
	Wheel4.wheel_friction_slip = normal_friction_slip_back
	physics_material_override.friction = 1

func boostSparking(delta):
	# Check if drift boost spark timer has expired
	if driftBoostSpark <= 0 and !is_drift_sparking1 && isOnGround:
		var DriftSparks1 = $DriftBoost1/GPUParticles3D
		var DriftSparks2 = $DriftBoost2/GPUParticles3D
		
		# Ensure particles exist before proceeding
		if DriftSparks1 and DriftSparks2:
			# Activate drift sparks only if on the ground, drifting, and timer condition is met
			if isOnGround and is_drifting:
				DriftSparks1.set_emitting(true)
				DriftSparks2.set_emitting(true)
				is_drift_sparking1 = true  # Set flag to avoid re-triggering unnecessarily
		else:
			DriftSparks1.set_emitting(false)
			DriftSparks2.set_emitting(false)
	else:
		# If the driftBoostSpark timer is greater than 0, or the drift has ended, stop the sparks
		if is_drift_sparking1:
			var DriftSparks1 = $DriftBoost1/GPUParticles3D
			var DriftSparks2 = $DriftBoost2/GPUParticles3D
			
			# Stop emitting particles
			if DriftSparks1 and DriftSparks2:
				DriftSparks1.set_emitting(false)
				DriftSparks2.set_emitting(false)
			
			is_drift_sparking1 = false  # Reset the flag
			
func _playerBoost(delta):
	if is_boosting && isOnGround:
		boost_timer -= delta  # Decrease the boost timer
		MAX_SPEED = MAX_SPEED_BOOST
		ENGINE_POWER = BOOST_ENGINE_POWER
		camera.fov = boost_fov
		
		var speed_lerp_boost_factor = 0.1
		speed_lerp_boost_factor = min(speed_lerp_boost_factor + delta * BOOST_SPEED_TRANSITION_RATE, 1.0)
		var forward_direction = global_transform.basis.z.normalized()
		var target_speed = forward_direction * float(target_speed_power)
		linear_velocity = linear_velocity.lerp(target_speed, 0.0)
		apply_central_impulse(forward_direction.normalized() * boostPower)

		if linear_velocity.length() > Initial_max_speed:
			linear_velocity = linear_velocity.normalized() * min(linear_velocity.length(), MAX_SPEED)

		if boost_timer <= 0:
			_end_boost()
	else:
		MAX_SPEED = Initial_max_speed
		ENGINE_POWER = Initial_engine_power


func _end_boost():
	is_boosting = false
	boost_timer = boostDuration
	MAX_SPEED = float(Initial_max_speed)
	ENGINE_POWER = float(Initial_engine_power)
	camera.fov = normal_fov

	if linear_velocity.length() > MAX_SPEED:
		linear_velocity = linear_velocity.normalized() * MAX_SPEED

	


