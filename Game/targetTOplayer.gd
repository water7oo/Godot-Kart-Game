extends Marker3D

@export var enabled: bool = true
@export var playerTarget: NodePath

var player_node: RigidBody3D

func _ready():
	# Ensure that playerTarget is a valid NodePath
	if playerTarget:
		player_node = get_node(playerTarget) as RigidBody3D
		if player_node == null:
			print("Error: playerTarget is not a Spatial node or it cannot be found.")
	else:
		print("playerTarget is not assigned or invalid")

func _physics_process(delta):
	StickToPlayer(delta)

func StickToPlayer(delta):
	# Ensure the functionality is enabled and player_node is valid
	if !enabled or not player_node:
		return

	# Update the position of the Marker3D to match the player's position
	position = player_node.global_transform.origin
