extends Node3D

const colors := [
	Color(1,0,1,0.5),
	Color(0,1,1,0.5),
	Color(1,1,0,0.5),
	Color(1,0,0,0.5),
	Color(0,1,0,0.5),
	Color(0,0,1,0.5),
	Color(1,0.5,0,0.5),
	Color(1,0,0.5,0.5),
	Color(0.5,1,0,0.5),
	Color(0,1,0.5,0.5),
	Color(0.5,0,1,0.5),
	Color(0,0.5,1,0.5),
]


func _ready():
	var color : Color = colors[randi() % colors.size()]
	$MeshInstance3D.get_active_material(0).emission = color
	$Cristal01.get_active_material(0).albedo_color = color

