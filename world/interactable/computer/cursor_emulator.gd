extends TransformContainer

var cursor_velocity: Vector2 = Vector2.ZERO

enum CursorType {
    Arrow,
    Pointer,
    NotAllowed,
    UpDownArrow
}

@export var arrow_cursor: Texture2D
@export var pointer_cursor: Texture2D
@export var not_allowed_cursor: Texture2D
@export var up_down_arrow_cursor: Texture2D

var cursor_pos: Vector2:
    set(pos):
        pos.x = clamp(0, pos.x, desktop_bounds.size.x)
        pos.y = clamp(0, pos.y, desktop_bounds.size.y)
        cursor_pos = pos
        visual_position = cursor_pos - Vector2(32, 32)

var current_cursor_type: CursorType = CursorType.Arrow:
    set(type):
        current_cursor_type = type
        update_cursor_sprite(type)

func update_cursor_sprite(type: CursorType):
    match type:
        CursorType.Arrow:
            $TextureRect.texture = arrow_cursor
        CursorType.Pointer:
            $TextureRect.texture = pointer_cursor
        CursorType.NotAllowed:
            $TextureRect.texture = not_allowed_cursor

@onready var desktop_bounds: Panel = $".."

var controlled_by_analog: bool = false
var scroll_debounce: float = 0.0
var was_scrolling: bool = false

const CURSOR_MOVEMENT_SPEED: float = 500
## Really high acceleration; makes small movements easier
const CURSOR_ACCELERATION: float = 10_000

const SCROLL_INTERVAL: float = 0.05

func _ready():
    update_cursor_sprite(current_cursor_type)
    cursor_pos = desktop_bounds.size / 2


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
    
    var real_delta = delta / Engine.time_scale

    var analog = Input.get_vector("move_left", "move_right", "move_up", "move_down")

    if Input.is_action_pressed("secondary_interact"):
        # scroll
        emulate_mouse_scroll(analog.y, real_delta)
        was_scrolling = true
    elif was_scrolling:
        was_scrolling = false
        emulate_scroll_end()
    
    else:
        cursor_velocity = cursor_velocity.move_toward(analog * CURSOR_MOVEMENT_SPEED, CURSOR_ACCELERATION * real_delta)
        if not cursor_velocity.is_zero_approx():
            emulate_mouse_motion(cursor_velocity, real_delta)

func _input(event: InputEvent) -> void:
    if not InputTargetSingleton.is_active(InputTargetSingleton.InputTarget.ComputerDesktop):
        return
    
    if event is InputEventMouse:
        var mouse_pos = event.position
        if is_in(desktop_bounds, mouse_pos):
            cursor_pos = mouse_pos - desktop_bounds.global_position

    if event.is_action_pressed("interact"):
        emulate_mouse_down(cursor_pos)
    elif event.is_action_released("interact"):
        emulate_mouse_up(cursor_pos)
    
    elif event.is_action_pressed("secondary_interact"):
        scroll_debounce = 0

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

func emulate_mouse_scroll(amount: float, delta: float):
    if amount == 0:
        return
    
    scroll_debounce -= delta
    if scroll_debounce > 0.0:
        return
    
    scroll_debounce = SCROLL_INTERVAL

    var screen_scale_factor = get_viewport().get_stretch_transform()

    var event = InputEventMouseButton.new()

    event.position = (cursor_pos + desktop_bounds.global_position) * screen_scale_factor
    event.button_index = MOUSE_BUTTON_WHEEL_UP if amount < 0 else MOUSE_BUTTON_WHEEL_DOWN
    event.pressed = true
    Input.parse_input_event(event)

func emulate_scroll_end():
    var screen_scale_factor = get_viewport().get_stretch_transform()

    var event = InputEventMouseButton.new()

    event.position = (cursor_pos + desktop_bounds.global_position) * screen_scale_factor
    event.button_index = MOUSE_BUTTON_WHEEL_UP
    event.pressed = false
    Input.parse_input_event(event)

    event = InputEventMouseButton.new()

    event.position = (cursor_pos + desktop_bounds.global_position) * screen_scale_factor
    event.button_index = MOUSE_BUTTON_WHEEL_DOWN
    event.pressed = false
    Input.parse_input_event(event)

func emulate_mouse_motion(velocity: Vector2, delta: float):
    var screen_scale_factor = get_viewport().get_stretch_transform()
    
    var event = InputEventMouseMotion.new()

    event.screen_relative = velocity * delta
    event.screen_velocity = velocity

    event.relative = velocity * delta * screen_scale_factor
    event.velocity = velocity * screen_scale_factor

    event.position = (cursor_pos + desktop_bounds.global_position + event.screen_relative) * screen_scale_factor
    cursor_pos += event.screen_relative

    Input.parse_input_event(event)
