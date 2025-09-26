extends Node2D

const InteractionData = preload("res://world/interactable/interactable.gd").InteractionData
const InteractionAction = preload("res://world/interactable/interactable.gd").InteractionAction

@export var building_tilemap: WorldInteractableTilemap
@export var automation_zones_tilemap: AutomationZonesTilemap
@export var automation_objects_tilemap: AutomationObjectsTilemap

@export_group("Colors", "highlight_")
@export var highlight_existing_color: Color
@export var highlight_valid_color: Color
@export var highlight_invalid_color: Color

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
    
    InteractionSingleton.interaction_data_changed.connect(update_interaction_info)

func update_interaction_info(data: InteractionData):
    if not is_visible_in_tree():
        return
    
    $%InteractionInfo.data = data

func _input(event):
    if not InputTargetSingleton.is_active(InputTargetSingleton.InputTarget.ConstructionMenu):
        return
    
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        hide_view()
        get_viewport().set_input_as_handled()
    
    for dir in movement_directions.keys():
        if Input.is_action_just_pressed_by_event(dir, event):
            _move_target(movement_directions[dir])
            repeat_countdown[dir] = REPEAT_INITIAL_DELAY
            get_viewport().set_input_as_handled()
        elif Input.is_action_just_released_by_event(dir, event):
            repeat_countdown.erase(dir)
            get_viewport().set_input_as_handled()
    
    # if event.is_action_pressed("cycle_right"):


func _process(delta):
    if abs(Engine.time_scale) < 0.001: 
        return
    
    delta = delta / Engine.time_scale
    if not InputTargetSingleton.is_active(InputTargetSingleton.InputTarget.ConstructionMenu):
        return
    
    camera.position_smoothing_speed = 5 / Engine.time_scale

    var highlighted_tile = automation_objects_tilemap.get_cell_tile_data(targeted_tile)
    var interaction_data: InteractionData = null
    var color

    if highlighted_tile != null:
        var interaction_zone = automation_zones_tilemap.get_cell_tile_data(targeted_tile)
        var editable = interaction_zone.get_custom_data("editable")

        if editable:
            var remove_action = InteractionAction.new("Remove", _remove_targeted_tile, 0.2)
            var rotate_action = InteractionAction.new("Rotate", _rotate_targeted_tile)
            interaction_data = InteractionData.new("Counter", "A counter. Manual machines\nmay be placed on top of it.", rotate_action, remove_action)
            color = highlight_existing_color
        else:
            interaction_data = InteractionData.new("Tile test", "A tile idk")
            color = highlight_invalid_color
    else:
        var zone_data = automation_zones_tilemap.get_cell_tile_data(targeted_tile)
        if zone_data != null and zone_data.get_custom_data("editable"):
            # todo: place tiles
            color = highlight_valid_color
        else:
            color = highlight_invalid_color
    
    InteractionSingleton.update_interactable(interaction_data)

    var target_position = building_tilemap.to_global(building_tilemap.map_to_local(targeted_tile))
    camera.global_position = target_position
    highlight.interp_to(target_position, color)
    
    for dir in repeat_countdown.keys():
        repeat_countdown[dir] -= delta
        if repeat_countdown[dir] < 0:
            repeat_countdown[dir] += REPEAT_INTERVAL
            _move_target(movement_directions[dir])

func _remove_targeted_tile():
    automation_objects_tilemap.set_cell(targeted_tile, -1)
    building_tilemap.update_around(targeted_tile)

func _rotate_targeted_tile():
    var tile_data = automation_objects_tilemap.get_cell_tile_data(targeted_tile)
    if tile_data == null:
        return
    
    var facing = tile_data.get_custom_data("facing")
    var new_atlas_coords = automation_objects_tilemap.get_cell_atlas_coords(targeted_tile)
    match facing:
        "up":
            # Right
            new_atlas_coords = Vector2i(0, 3)
        "right":
            # Down
            new_atlas_coords = Vector2i(0, 2)
        "down":
            # Left
            new_atlas_coords = Vector2i(0, 4)
        "left":
            # Up
            new_atlas_coords = Vector2i(0, 1)
    
    automation_objects_tilemap.set_cell(
        targeted_tile,
        automation_objects_tilemap.get_cell_source_id(targeted_tile),
        new_atlas_coords,
        automation_objects_tilemap.get_cell_alternative_tile(targeted_tile)
    )
    building_tilemap.update_around(targeted_tile)
    

func _move_target(dir: Vector2i):
    var zone_data = automation_zones_tilemap.get_cell_tile_data(targeted_tile + dir)
    if zone_data == null:
        return
    
    targeted_tile += dir

func show_view():
    visible = true

    if old_camera:
        return
    
    old_camera = get_viewport().get_camera_2d()
    camera.activate_camera()

    InputTargetSingleton.activate(InputTargetSingleton.InputTarget.ConstructionMenu)
    set_process(true)

    automation_objects_tilemap.show_map()

func hide_view():
    visible = false

    if old_camera:
        old_camera.activate_camera()
        old_camera = null
    
    repeat_countdown.clear()

    InputTargetSingleton.deactivate(InputTargetSingleton.InputTarget.ConstructionMenu)
    set_process(false)

    automation_objects_tilemap.hide_map()
