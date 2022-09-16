extends Node3D

const TERRAIN_CHUNK := preload("res://objects/terrain_chunk.tscn")

@export var noise : Noise
@export var noise2 : Noise
@export var material_terrain : Material

@onready var node_terrain := $"%Terrain" as Node3D
@onready var world_environment := $WorldEnvironment as WorldEnvironment
@onready var player := $"%Player" as Node3D

var level_loaded := false
var list_chunks := []


func _ready():
	noise.seed = randi()
	noise2.seed = randi()
	player.position.y = 101.4


func _process(_delta):
	$Label.text = str(Engine.get_frames_per_second())


func _unhandled_input(_event):
	if Input.is_action_just_pressed("FullScreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
#	get_viewport().scaling_3d_scale = 0.5
#	get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR


func _on_timer_rebuild_timeout():
	var pos_x := int(floor(player.global_position.x) / 10)
	var pos_z := int(floor(player.global_position.z) / 10)
	var load_dist := 5
	for child in list_chunks:
		child.set_meta("remove_me", true)
	for z in range(pos_z - load_dist, pos_z + load_dist):
		for x in range(pos_x - load_dist, pos_x + load_dist):
			name = "Terrain " + str(x) + "_" + str(z)
			if node_terrain.has_node(NodePath(name)):
				var no = node_terrain.get_node(NodePath(name))
				no.set_meta("remove_me", null)
				continue
			var node : Node3D = TERRAIN_CHUNK.instantiate()
			node_terrain.add_child(node)
			node.noise = noise
			node.noise2 = noise2
			node.material_terrain = material_terrain
			node.build_terrain(x, z)
			list_chunks.append(node)
			return
	if not level_loaded:
		level_loaded = true
		$Elevator.position.y = 0.25
		$Elevator.open()
		player.set_can_move(true)
		player.position.y = $Elevator.position.y + 1.4
		$"%LabelLoading".visible = false
		#$TimerRebuild.stop()
	var repeat := true
	while repeat:
		repeat = false
		for child in list_chunks:
			if child.has_meta("remove_me"):
				child.queue_free()
				list_chunks.erase(child)
				repeat = true
				break
