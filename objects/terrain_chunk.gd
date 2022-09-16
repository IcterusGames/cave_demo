extends Node3D

const PLANT_01 := preload("res://objects/plant_01.tscn")
const PLANT_02 := preload("res://objects/cristal_01.tscn")
const CREATE_CEIL : bool = true
const CREATE_PLANTS : bool = true
const CREATE_PHYSICS : bool = true
const resolution : int = 50
const scale_y : float = 20
const ceil_height : float = 5

var noise : Noise
var noise2 : Noise
var material_terrain : Material
var thread := Thread.new()
var mutex := Mutex.new()
var exit_thread := false
var mesh_floor := ArrayMesh.new()
var mesh_ceil := ArrayMesh.new()
var node_floor : Node3D
var node_ceil : Node3D
var static_body_floor := StaticBody3D.new()
var static_body_ceil := StaticBody3D.new()
var plants := []


func _exit_tree():
	mutex.lock()
	exit_thread = true
	mutex.unlock()
	thread.wait_to_finish()


func build_terrain(x : int, z : int):
	name = "Terrain " + str(x) + "_" + str(z)
	thread.start(Callable(self, "_build_meshes_threaded").bind(x * 10, z * 10))


func _build_meshes_threaded(x : int, z : int):
	var should_exit := false
	create_floor(x, z)
	mutex.lock()
	should_exit = exit_thread
	mutex.unlock()
	if should_exit:
		return
	node_floor = MeshInstance3D.new()
	node_floor.mesh = mesh_floor
	node_floor.material_override = material_terrain
	node_floor.add_child(static_body_floor)
	
	if CREATE_CEIL:
		create_ceil(x, z)
		mutex.lock()
		should_exit = exit_thread
		mutex.unlock()
		if should_exit:
			return
		node_ceil = MeshInstance3D.new()
		node_ceil.mesh = mesh_ceil
		node_ceil.material_override = material_terrain
		node_ceil.add_child(static_body_ceil)
	
	call_deferred("_build_meshes_finished", x, z)


func _build_meshes_finished(x : int, z : int):
	add_child(node_floor)
	node_floor.position.x = x
	node_floor.position.z = z
	
	if CREATE_PLANTS:
		for zo in 10:
			for xo in 10:
				if Vector2(x + xo, z + zo).distance_squared_to(Vector2.ZERO) < 20:
					# No generar plantas dentro del elevador
					continue
				var r : int = int(noise.get_noise_2d(x + xo, z + zo) * 100)
				if r == 20:
					var plant : Node3D = PLANT_02.instantiate()
					node_floor.add_child(plant)
					plant.position.x = xo
					plant.position.z = zo
					plant.position.y = get_pos_y(x + xo, z + zo) - 0.1
					plant.rotation.y = randf() * PI * 2.0
					var n = get_normal(x + xo, z + zo)
					var b := Basis()
					b.x = n.cross(plant.global_transform.basis.z)
					b.y = n
					b.z = plant.global_transform.basis.x.cross(n)
					plant.global_transform.basis = b
				
				if randi_range(0, 100) == 5:
					var plant : Node3D = PLANT_01.instantiate()
					node_floor.add_child(plant)
					plant.position.x = xo
					plant.position.z = zo
					plant.position.y = get_pos_y(x + xo, z + zo) - 0.1
					plant.rotation.y = randf() * PI * 2.0
					var n = get_normal(x + xo, z + zo)
					var b := Basis()
					b.x = n.cross(plant.global_transform.basis.z)
					b.y = n
					b.z = plant.global_transform.basis.x.cross(n)
					plant.global_transform.basis = b
	
	if CREATE_CEIL:
		add_child(node_ceil)
		node_ceil.position.x = x
		node_ceil.position.z = z


func get_pos_y(x : float, z : float, isfloor : bool = true) -> float:
	if isfloor:
		var ret = abs(noise.get_noise_2d(x, z)) * clamp(noise2.get_noise_2d(x, z), 0, 1)
		ret *= scale_y
		ret += noise.get_noise_2d(x * 0.1, z * 0.1) * 50 # Generador de elevaciones
		ret *= clamp(Vector2(x, z).distance_to(Vector2.ZERO) * 0.03, 0, 1) # Garantiza que el punto inicial siempre sea cero
		ret += noise.get_noise_2d(x * 10, z * 10) * 0.4 # Ruido detalles
		return ret
	var ret = noise.get_noise_2d(x + 1024, z + 2048) * clamp(noise2.get_noise_2d(x + 1024, z + 2048), 0, 1)
	ret *= scale_y
	ret *= -1
	ret += noise.get_noise_2d(x * 0.1, z * 0.1) * 50 # Generador de elevaciones
	ret *= clamp(Vector2(x, z).distance_to(Vector2.ZERO) * 0.03, 0, 1) # Garantiza que el punto inicial siempre sea cero
	ret += ceil_height
	ret += abs(noise.get_noise_2d((x - 1024) * 0.2, (z - 2048) * 0.2)) * ceil_height # Generador de cuevas altas
	ret += noise.get_noise_2d(x * 10, z * 10) * 0.4 # Ruido detalles
	return ret


func get_normal(world_x : float, world_z : float) -> Vector3:
	var v1 := Vector3.ZERO
	var vn := Vector3.ZERO
	var vs := Vector3.ZERO
	var ve := Vector3.ZERO
	var vw := Vector3.ZERO
	var s_factor : float = 10 / float(resolution);
	v1.x = 0 * s_factor
	v1.z = 0 * s_factor
	v1.y = get_pos_y(world_x + v1.x, world_z + v1.z)
	vn.x = 0 * s_factor
	vn.z = (0 - 1) * s_factor
	vn.y = get_pos_y(world_x + vn.x, world_z + vn.z)
	vs.x = 0 * s_factor
	vs.z = (0 + 1) * s_factor
	vs.y = get_pos_y(world_x + vs.x, world_z + vs.z)
	ve.x = (0 + 1) * s_factor
	ve.z = 0 * s_factor
	ve.y = get_pos_y(world_x + ve.x, world_z + ve.z)
	vw.x = (0 - 1) * s_factor
	vw.z = 0 * s_factor
	vw.y = get_pos_y(world_x + vw.x, world_z + vw.z)
	return ((vs - v1).cross(ve - v1).normalized() + \
		(vw - vn).cross(v1 - vn).normalized() + \
		(vn - ve).cross(v1 - ve).normalized() + \
		(ve - vs).cross(v1 - vs).normalized() + \
		(vs - vw).cross(v1 - vw).normalized()).normalized()


func create_floor(world_x : int, world_z : int):
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var index := PackedInt32Array()
	var heigmap_data := PackedFloat32Array()
	var s_factor : float = 10 / float(resolution);
	var res : int = resolution + 1
	
	var v1 := Vector3.ZERO
	var vn := Vector3.ZERO
	var vs := Vector3.ZERO
	var ve := Vector3.ZERO
	var vw := Vector3.ZERO
	for z in res:
		mutex.lock()
		var should_exit = exit_thread
		mutex.unlock()
		if should_exit:
			break
		for x in res:
			v1.x = x * s_factor
			v1.z = z * s_factor
			v1.y = get_pos_y(world_x + v1.x, world_z + v1.z)
			vn.x = x * s_factor
			vn.z = (z - 1) * s_factor
			vn.y = get_pos_y(world_x + vn.x, world_z + vn.z)
			vs.x = x * s_factor
			vs.z = (z + 1) * s_factor
			vs.y = get_pos_y(world_x + vs.x, world_z + vs.z)
			ve.x = (x + 1) * s_factor
			ve.z = z * s_factor
			ve.y = get_pos_y(world_x + ve.x, world_z + ve.z)
			vw.x = (x - 1) * s_factor
			vw.z = z * s_factor
			vw.y = get_pos_y(world_x + vw.x, world_z + vw.z)
			if CREATE_PHYSICS:
				heigmap_data.push_back(v1.y)
			vertices.push_back(v1)
			normals.push_back(((vs - v1).cross(ve - v1).normalized() + \
				(vw - vn).cross(v1 - vn).normalized() + \
				(vn - ve).cross(v1 - ve).normalized() + \
				(ve - vs).cross(v1 - vs).normalized() + \
				(vs - vw).cross(v1 - vw).normalized()).normalized())
			uvs.push_back(Vector2(float(x) / (res-1), float(z) / (res-1)))
	
	mutex.lock()
	var should_exit = exit_thread
	mutex.unlock()
	if should_exit:
		return
	
	var i : int = 0
	for z in res - 1:
		for x in res - 1:
			index.push_back(i)
			index.push_back(i+1)
			index.push_back(i+res)
			index.push_back(i+res+1)
			index.push_back(i+res)
			index.push_back(i+1)
			i += 1
		i += 1
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals
	arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
	arrays[ArrayMesh.ARRAY_TEX_UV2] = uvs
	arrays[ArrayMesh.ARRAY_INDEX] = index
	
	mesh_floor.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	if CREATE_PHYSICS:
		# Fisicas por medio de HeightMapShape3D
		var shape := CollisionShape3D.new()
		var heighmap := HeightMapShape3D.new()
		shape.scale.x *= s_factor;
		shape.scale.z *= s_factor;
		shape.position.x = (resolution * s_factor) / 2.0
		shape.position.z = (resolution * s_factor) / 2.0
		static_body_floor.add_child(shape)
		heighmap.map_width = res
		heighmap.map_depth = res
		heighmap.map_data = heigmap_data;
		shape.shape = heighmap


func create_ceil(world_x : int, world_z : int):
	var vertices := PackedVector3Array()
	var vertices_phy := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var index := PackedInt32Array()
	var s_factor : float = 10 / float(resolution);
	var res : int = resolution + 1
	
	var v1 := Vector3.ZERO
	var vn := Vector3.ZERO
	var vs := Vector3.ZERO
	var ve := Vector3.ZERO
	var vw := Vector3.ZERO
	for z in res:
		mutex.lock()
		var should_exit = exit_thread
		mutex.unlock()
		if should_exit:
			break
		for x in res:
			v1.x = x * s_factor
			v1.z = z * s_factor
			v1.y = get_pos_y(world_x + v1.x, world_z + v1.z, false)
			vn.x = x * s_factor
			vn.z = (z - 1) * s_factor
			vn.y = get_pos_y(world_x + vn.x, world_z + vn.z, false)
			vs.x = x * s_factor
			vs.z = (z + 1) * s_factor
			vs.y = get_pos_y(world_x + vs.x, world_z + vs.z, false)
			ve.x = (x + 1) * s_factor
			ve.z = z * s_factor
			ve.y = get_pos_y(world_x + ve.x, world_z + ve.z, false)
			vw.x = (x - 1) * s_factor
			vw.z = z * s_factor
			vw.y = get_pos_y(world_x + vw.x, world_z + vw.z, false)
			vertices.push_back(v1)
			normals.push_back(((vs - v1).cross(ve - v1).normalized() + \
				(vw - vn).cross(v1 - vn).normalized() + \
				(vn - ve).cross(v1 - ve).normalized() + \
				(ve - vs).cross(v1 - vs).normalized() + \
				(vs - vw).cross(v1 - vw).normalized()).normalized() * -1)
			uvs.push_back(Vector2(float(x) / resolution, float(z) / resolution))
			
			if CREATE_PHYSICS:
				vertices_phy.push_back(Vector3(v1))
				vertices_phy.push_back(Vector3(vs))
				vertices_phy.push_back(Vector3(ve))
				vertices_phy.push_back(Vector3(ve))
				vertices_phy.push_back(Vector3(vs))
				vw.x = (x + 1) * s_factor
				vw.z = (z + 1) * s_factor
				vw.y = get_pos_y(world_x + vw.x, world_z + vw.z, false)
				vertices_phy.push_back(vw)
	
	mutex.lock()
	var should_exit = exit_thread
	mutex.unlock()
	if should_exit:
		return
	
	var i : int = 0
	for z in res - 1:
		for x in res - 1:
			index.push_back(i+res)
			index.push_back(i+1)
			index.push_back(i)
			index.push_back(i+1)
			index.push_back(i+res)
			index.push_back(i+res+1)
			i += 1
		i += 1
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals
	arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
	arrays[ArrayMesh.ARRAY_INDEX] = index
	
	mesh_ceil.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	if CREATE_PHYSICS:
		var shape := CollisionShape3D.new()
		var body := ConcavePolygonShape3D.new()
		body.set_faces(vertices_phy)
		shape.shape = body
		static_body_ceil.add_child(shape)

