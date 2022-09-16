extends Node3D

var _can_move : bool = false
var _speed : float = 2.0
var _cam_rot_x : float = 0.0
var _cam_rot_y : float = 0.0
var _mouse_look : bool = true
@onready var _axis_x := $"%CameraAxisX" as Node3D
@onready var _camera := $"%Camera3D" as Camera3D


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN


func _process(delta):
	if Engine.is_editor_hint():
		return
	if _can_move:
		var dir := _camera.project_ray_normal(get_viewport().get_visible_rect().size / 2)
		position += dir * _speed * delta * Input.get_action_strength("move_forward")
		position += dir * -_speed * delta * Input.get_action_strength("move_backward")
		dir = Vector3.FORWARD.rotated(Vector3.UP, rotation.y + PI / 2.0)
		position += _speed * delta * dir * Input.get_action_strength("move_left")
		dir = Vector3.FORWARD.rotated(Vector3.UP, rotation.y - PI / 2.0)
		position += _speed * delta * dir * Input.get_action_strength("move_right")
	
	rotation.y += 2.0 * delta * (Input.get_action_strength("look_left") + Input.get_action_strength("look_right") * -1)
	_axis_x.rotation.x += 2.0 * delta * (Input.get_action_strength("look_up") + Input.get_action_strength("look_down") * -1)
	rotation.y += _cam_rot_y * delta * _speed
	_axis_x.rotation.x += _cam_rot_x * delta * _speed
	_cam_rot_y -= _cam_rot_y * delta * _speed
	_cam_rot_x -= _cam_rot_x * delta * _speed


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_mouse_look = !_mouse_look
			if _mouse_look:
				Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion:
		if _mouse_look:
			_cam_rot_y += event.relative.x * -0.01
			_cam_rot_x += event.relative.y * -0.01


func set_can_move(can_move : bool):
	_can_move = can_move

