extends Node3D

#Make cam target script that follows players position
@export var target: NodePath
@export var speed := 1.0
@export var rotation_speed := 1.0
@export var enabled: bool
@export var spring_arm_pivot: Node3D
@onready var camera = $SpringArmPivot/SpringArm3D/Camera3D
var cam_lerp_speed = .005

var original_global_transform: Transform3D
var target_node: Node3D

func _ready():
	target_node = get_node(target) as Node3D


func _physics_process(delta):
	followTarget(delta)




func followTarget(delta):
	if not enabled or not target_node:
		return

	var new_global_transform = global_transform.interpolate_with(target_node.global_transform, speed * delta)
	var new_rotation = global_transform.basis.slerp(target_node.global_transform.basis, rotation_speed * delta)
	
	global_transform = new_global_transform
	global_transform.basis = new_rotation
	
	#Assign rotation variable for camera follow
	

