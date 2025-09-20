extends Node2D

@export var building_tilemap: WorldInteractableTilemap

@onready var camera: UiCamera2D = $Camera2D
@onready var highlight = $InteractionHighlight

var targeted_tile: Vector2i = Vector2i.ZERO

# For key repeat logic. We use custom repeating instead of normal input repeats since that's OS-specific and pretty unreliable from my experience
var repeat_countdown: Dictionary[StringName, float] = {}
const REPEAT_INITIAL_DELAY = 0.3
const REPEAT_INTERVAL = 0.1

var movement_directions: Dictionary[StringName, Vector2i] = {
    "move_up": Vector2i.UP,
    "move_down": Vector2i.DOWN,
    "move_left": Vector2i.LEFT,
    "move_right": Vector2i.RIGHT
}

var old_camera: UiCamera2D = null

func _ready():
    visible = false

    var tilemap_cells = building_tilemap.get_used_cells()
    var min_x = 100000
    var min_y = 100000
    var max_x = -100000
    var max_y = -100000
    for cell in tilemap_cells:
        var pos = building_tilemap.to_global(building_tilemap.map_to_local(cell))
        min_x = min(min_x, pos.x)
        min_y = min(min_y, pos.y)
        max_x = max(max_x, pos.x)
        max_y = max(max_y, pos.y)
    
    # Set camera bounds based on the tilemap extent
    var margin = Vector2(building_tilemap.tile_set.tile_size * 3)
    camera.limit_left = int(min_x - margin.x)
    camera.limit_top = int(min_y - margin.y)
    camera.limit_right = int(max_x + margin.x)
    camera.limit_bottom = int(max_y + margin.y)

    @warning_ignore("integer_division")
    targeted_tile = tilemap_cells[tilemap_cells.size() / 2]

    set_process(false)

func _input(event):
    if not InputTargetSingleton.is_active(InputTargetSingleton.InputTarget.ConstructionMenu):
        return
    
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        hide_view()
        get_viewport().set_input_as_handled()
    
    for dir in movement_directions.keys():
        if Input.is_action_just_pressed(dir):
            targeted_tile += movement_directions[dir]
            repeat_countdown[dir] = REPEAT_INITIAL_DELAY
            get_viewport().set_input_as_handled()
        elif Input.is_action_just_released(dir):
            repeat_countdown.erase(dir)
            get_viewport().set_input_as_handled()

func _process(delta):
    delta = delta / Engine.time_scale
    if not InputTargetSingleton.is_active(InputTargetSingleton.InputTarget.ConstructionMenu):
        return
    
    camera.position_smoothing_speed = 5 / Engine.time_scale

    $%InteractionInfo.data = null # TODO

    var target_position = building_tilemap.to_global(building_tilemap.map_to_local(targeted_tile))
    camera.global_position = target_position
    highlight.global_position = target_position
    
    for dir in repeat_countdown.keys():
        repeat_countdown[dir] -= delta
        if repeat_countdown[dir] < 0:
            repeat_countdown[dir] += REPEAT_INTERVAL
            targeted_tile += movement_directions[dir]

func show_view():
    visible = true

    if old_camera:
        return
    
    old_camera = get_viewport().get_camera_2d()
    camera.activate_camera()

    InputTargetSingleton.activate(InputTargetSingleton.InputTarget.ConstructionMenu)
    set_process(true)

func hide_view():
    visible = false

    if old_camera:
        old_camera.activate_camera()
        old_camera = null
    
    repeat_countdown.clear()

    InputTargetSingleton.deactivate(InputTargetSingleton.InputTarget.ConstructionMenu)
    set_process(false)
