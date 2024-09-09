extends Marker3D

@export var enabled: bool = true
@export var target: NodePath
@export var speed := 1.0
@export var rotation_speed := 1.0

var original_global_transform: Transform3D
var target_node: Node3D

var player_node: RigidBody3D

func _ready():
	pass

func _physics_process(delta):
	followTarget(delta)

func followTarget(delta):
	pass

