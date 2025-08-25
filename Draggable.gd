class_name Draggable
extends Area3D

signal on_drag_began (mouse_position: Vector2)
signal on_dragged (mouse_position: Vector2)
signal on_drag_ended (mouse_position: Vector2)
signal on_hover_entered
signal on_hover_exited
signal on_clicked (mouse_position: Vector2)

## Root node where the _drag will be applied
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

var _offset: Vector3 = Vector3.ZERO
var _target_position: Vector3 = Vector3.ZERO
var _begin_drag_lerp: float = 0.0
var _drag_origin: Vector3
var _is_being_dragged: bool
var _is_hovering: bool


func _ready() -> void:
	mouse_entered.connect(_handle_mouse_entered)
	mouse_exited.connect(_handle_mouse_exited)
	get_tree().process_frame.connect(_handle_process)
	if !root:
		root = self
	input_capture_on_drag = true


func _handle_mouse_entered ():
	_is_hovering = true
	InputController.mouse_enter(self)
	if !hoverable:
		return
	on_hover_entered.emit()
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _handle_mouse_exited ():
	_is_hovering = false
	InputController.mouse_exit(self)
	if not hoverable:
		return
	on_hover_exited.emit()
	if not _is_being_dragged:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _handle_process ():
	if not _is_being_dragged or not draggable:
		return
	if is_equal_approx(_begin_drag_lerp, 1.0):
		root.global_position = _target_position
	elif not use_offset:
		root.global_position = _drag_origin.lerp(_target_position, _begin_drag_lerp)


func _before_begin_drag (mouse_position: Vector2):
	if not draggable or _is_being_dragged:
		return
	Input.set_default_cursor_shape(Input.CURSOR_MOVE)
	_is_being_dragged = true
	on_drag_began.emit(mouse_position)
	var point = InputController.mouse_to_world_position(mouse_position)
	_target_position = point + _offset + drag_offset
	if not drag_from_pivot:
		_offset = root.global_position - point
	_begin_drag_lerp = 0.0
	_drag_origin = root.global_position
	if not use_offset:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "_begin_drag_lerp", 1.0, 0.2)
	_begin_drag(mouse_position)


func _before_drag (mouse_position: Vector2):
	if not draggable or not _is_being_dragged:
		return
	on_dragged.emit(mouse_position)
	var point = InputController.mouse_to_world_position(mouse_position)
	_target_position = point + _offset + drag_offset
	if use_offset and not is_equal_approx(_begin_drag_lerp, 1.0):
		_begin_drag_lerp = clamp(_begin_drag_lerp + begin_drag_speed * get_process_delta_time(), 0.0, 1.0)
		root.global_position = _drag_origin.lerp(_target_position, _begin_drag_lerp)
	_drag(mouse_position)


func _before_end_drag (mouse_position: Vector2):
	if not draggable:
		return
	_is_being_dragged = false
	on_drag_ended.emit(mouse_position)
	if _is_hovering:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	_end_drag(mouse_position)


func _before_click (mouse_position: Vector2):
	on_clicked.emit(mouse_position)
	_click(mouse_position)


func _begin_drag (_mouse_position: Vector2):
	pass


func _drag (_mouse_position: Vector2):
	pass


func _end_drag (_mouse_position: Vector2):
	pass


func _click (_mouse_position: Vector2):
	Debug.logm("Clicked!")
	pass
