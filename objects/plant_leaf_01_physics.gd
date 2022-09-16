extends Node3D


func _ready():
	await get_tree().process_frame
	$Armature001/Skeleton3D.physical_bones_start_simulation()

