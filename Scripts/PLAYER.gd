extends VehicleBody3D

var camera = preload("res://PlayerKart/camera.tscn").instantiate()
var spring_arm_pivot = camera.get_node("SpringArmPivot")
var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")
var playerLook = camera.get_node("SpringArmPivot/MeshInstance3D")


@export var MAX_STEER = 0.4
@export var ENGINE_POWER = 140
var jumpUses = 1 



@export var mouse_sensitivity = .005
@export var joystick_sensitivity = .005
@export var cam_target : Node3D
@onready var mass_center_node = $CenterOfMass

var can_jump = true


func _ready():
	pass # Replace with function body.


func _physics_process(delta):
	_proccess_movement(delta)
	_proccess_drifting(delta)


func _proccess_movement(delta):
	var right_input = Input.get_action_strength("move_right")
	var left_input = Input.get_action_strength("move_left")

	var steering =  left_input - right_input
	steering = clamp(steering, -MAX_STEER, MAX_STEER)
	
	set_steering(steering * MAX_STEER)
	
	var engine_force = Input.get_axis("move_brake", "move_gas") * ENGINE_POWER 
	
	set_engine_force(engine_force)
	set_brake(Input.get_action_strength("move_brake") * ENGINE_POWER)
	
	
	
	if Input.is_action_pressed("move_gas"):
		print("GAS")
		
	

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit_game"):
		print("GAME QUIT")
		get_tree().quit()
		
	
	
	
func _proccess_drifting(delta):
	if Input.is_action_just_pressed("move_drift"):
		print("Drifting")
