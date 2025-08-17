extends Area3D

class_name Draggable

signal on_begin_drag (mouse_position: Vector2)
signal on_drag (mouse_position: Vector2)
signal on_end_drag (mouse_position: Vector2)
signal on_hover_enter
signal on_hover_exit
signal on_click (mouse_position: Vector2)

## Root node where the drag will be applied
@export var root: Node
## If set to TRUE, the object can be hovered.
@export var hoverable: bool = true
## If set to TRUE, the object can be dragged.
@export var draggable: bool = true
## If set to TRUE, the object will be dragged from its pivot point.
@export var drag_from_pivot: bool = true
## Set an offset to be applied when dragging the object.
@export var drag_offset: Vector3 = Vector3.ZERO
## If set to TRUE, the input will be captured when dragging the object.
@export var use_offset: bool = false
## Speed of the lerp when dragging the object.
@export var begin_drag_speed: float = 1.0

var _plane: Plane
var _camera: Camera3D
var _offset: Vector3 = Vector3.ZERO
var _target_position: Vector3 = Vector3.ZERO
var _begin_drag_lerp: float = 0.0
var _drag_origin: Vector3
var _is_being_dragged: bool
# TODO Move threshold management to InputController
var _input_start_time: int
var _input_start_position: Vector2

func _enter_tree() -> void:
	ready.connect(_handle_ready)
	mouse_entered.connect(_handle_mouse_entered)
	mouse_exited.connect(_handle_mouse_exited)
	get_tree().process_frame.connect(_handle_process)
	input_event.connect(_handle_input_event)

func _handle_ready ():
	if !root:
		root = self
	input_capture_on_drag = true
	_plane = InputController.plane

func _handle_mouse_entered ():
	if !hoverable:
		return
	on_hover_enter.emit()
	InputController.mouse_enter(self)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _handle_mouse_exited ():
	if !hoverable:
		return
	on_hover_exit.emit()
	InputController.mouse_exit(self)
	if !InputController.is_dragging:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _handle_process ():
	if !_is_being_dragged or !draggable:
		return
	if is_equal_approx(_begin_drag_lerp, 1.0):
		root.global_position = _target_position
	elif !use_offset:
		root.global_position = _drag_origin.lerp(_target_position, _begin_drag_lerp)

func _handle_input_event (camera: Camera3D, event: InputEvent, _event_position: Vector3,
			_normal: Vector3, _shape_idx: int) -> void:
	if !_camera:
		_camera = camera
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			_input_start_time = Time.get_ticks_msec()
			_input_start_position = event.position
			if !InputController.is_dragging:
				_before_begin_drag(event.position)
		elif event.is_released():
			if Time.get_ticks_msec() - _input_start_time <= InputController.click_threshold_time_ms \
				and _input_start_position.distance_to(event.position) \
					<= InputController.click_threshold_distance:
				on_click.emit(event.position)
				click(event.position)
			if InputController.is_dragging:
				_before_end_drag(event.position)

func _before_begin_drag (mouse_position: Vector2):
	if !draggable or InputController.is_dragging:
		return
	on_begin_drag.emit(mouse_position)
	Input.set_default_cursor_shape(Input.CURSOR_MOVE)
	InputController.begin_drag(self)
	_is_being_dragged = true
	var point = InputController.mouse_to_world_position(mouse_position)
	_target_position = point + _offset + drag_offset
	if !drag_from_pivot:
		_offset = root.global_position - point
	_begin_drag_lerp = 0.0
	_drag_origin = root.global_position
	if !use_offset:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "_begin_drag_lerp", 1.0, 0.2)
	begin_drag(mouse_position)

func _before_drag (mouse_position: Vector2):
	if !draggable or !_is_being_dragged:
		return
	on_drag.emit(mouse_position)
	var point = InputController.mouse_to_world_position(mouse_position)
	_target_position = point + _offset + drag_offset
	if use_offset and !is_equal_approx(_begin_drag_lerp, 1.0):
		_begin_drag_lerp = clamp(_begin_drag_lerp + begin_drag_speed * get_process_delta_time(), 0.0, 1.0)
		root.global_position = _drag_origin.lerp(_target_position, _begin_drag_lerp)
	drag(mouse_position)

func _before_end_drag (_mouse_position: Vector2):
	if !draggable:
		return
	_is_being_dragged = false
	on_end_drag.emit(_mouse_position)
	InputController.end_drag(self)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	end_drag(_mouse_position)

func begin_drag (_mouse_position: Vector2):
	pass

func drag (_mouse_position: Vector2):
	pass

func end_drag (_mouse_position: Vector2):
	pass

func click (_mouse_position: Vector2):
	Debug.logm("Clicked!")
	pass
