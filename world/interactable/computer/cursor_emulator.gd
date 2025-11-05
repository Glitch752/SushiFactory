extends TransformContainer

var cursor_velocity: Vector2 = Vector2.ZERO

enum CursorType {
    Arrow,
    Pointer,
    NotAllowed
}

var cursor_offsets: Dictionary[CursorType, Vector2] = {
    CursorType.Arrow: Vector2()
}

var cursor_pos: Vector2:
    set(pos):
        pos.x = clamp(0, pos.x, desktop_bounds.size.x)
        pos.y = clamp(0, pos.y, desktop_bounds.size.y)
        cursor_pos = pos
        visual_position = cursor_pos
var current_cursor_type: CursorType = CursorType.Arrow

@onready var desktop_bounds: Panel = $".."

var controlled_by_analog: bool = false

const CURSOR_MOVEMENT_SPEED: float = 20000.
## Really high acceleration; makes small movements easier
const CURSOR_ACCELERATION: float = 10_000_000

func _ready():
    pass


func is_in(node: Control, point: Vector2):
    return (
        point.x >= node.global_position.x and
        point.y >= node.global_position.y and
        point.x <= node.global_position.x + node.size.x and
        point.y <= node.global_position.y + node.size.y
    )

func _process(delta: float) -> void:
    if not InputTargetSingleton.is_active(InputTargetSingleton.InputTarget.ComputerDesktop):
        return

    var analog = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    cursor_velocity = cursor_velocity.move_toward(analog * CURSOR_MOVEMENT_SPEED, CURSOR_ACCELERATION * delta)

    if not cursor_velocity.is_zero_approx():
        emulate_mouse_motion(cursor_velocity, delta)

func _input(event: InputEvent) -> void:
    if not InputTargetSingleton.is_active(InputTargetSingleton.InputTarget.ComputerDesktop):
        return
    
    if event is InputEventMouseMotion:
        var mouse_pos = event.position
        if is_in(desktop_bounds, mouse_pos):
            cursor_pos = mouse_pos - desktop_bounds.global_position
    
    if event.is_action_pressed("interact"):
        emulate_mouse_down(cursor_pos)
    elif event.is_action_released("interact"):
        emulate_mouse_up(cursor_pos)

func emulate_mouse_down(pos: Vector2):
    var event = InputEventMouseButton.new()
    
    var screen_scale_factor = get_viewport().get_stretch_transform()
    event.position = (pos + desktop_bounds.global_position) * screen_scale_factor

    event.button_index = MOUSE_BUTTON_LEFT
    event.pressed = true
    Input.parse_input_event(event)

func emulate_mouse_up(pos: Vector2):
    var event = InputEventMouseButton.new()
    
    var screen_scale_factor = get_viewport().get_stretch_transform()
    event.position = (pos + desktop_bounds.global_position) * screen_scale_factor
    
    event.button_index = MOUSE_BUTTON_LEFT
    event.pressed = false
    Input.parse_input_event(event)

func emulate_mouse_motion(velocity: Vector2, delta: float):
    var event = InputEventMouseMotion.new()

    var screen_scale_factor = get_viewport().get_stretch_transform()
    
    event.screen_relative = velocity * delta
    event.screen_velocity = velocity

    event.relative = velocity * delta * screen_scale_factor
    event.velocity = velocity * screen_scale_factor

    event.position = (cursor_pos + desktop_bounds.global_position + event.screen_relative) * screen_scale_factor
    cursor_pos += event.screen_relative

    Input.parse_input_event(event)
