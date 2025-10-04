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
@onready var constructable_list = $%ConstructionInterface/%ConstructableView

var targeted_tile: Vector2i = Vector2i.ZERO
var target_direction: String = "up"

var constructable_index: int = 0

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
    
    $%ConstructionInterface/%InteractionInfo.data = data

func _input(event):
    if not InputTargetSingleton.is_active(InputTargetSingleton.InputTarget.ConstructionMenu):
        return
    
    if event.is_action_pressed("pause"):
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
    
    if event.is_action_pressed("rotate_left"):
        constructable_index = (constructable_index - 1 + DataLoader.constructables.size()) % DataLoader.constructables.size()
        constructable_list.selected = constructable_index
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("rotate_right"):
        constructable_index = (constructable_index + 1) % DataLoader.constructables.size()
        constructable_list.selected = constructable_index
        get_viewport().set_input_as_handled()


func _process(delta):
    if abs(Engine.time_scale) < 0.001: 
        return
    
    delta = delta / Engine.time_scale
    if not InputTargetSingleton.is_active(InputTargetSingleton.InputTarget.ConstructionMenu):
        return
    
    camera.position_smoothing_speed = 5 / Engine.time_scale

    var highlighted_tile = automation_objects_tilemap.get_cell_tile_data(targeted_tile)
    var highlight_zone = automation_zones_tilemap.get_cell_tile_data(targeted_tile)
        
    var context = ConstructableData.SillyConstructionContext.new()
    context.rotate_targeted_tile = _rotate_targeted_tile
    context.remove_targeted_tile = _remove_targeted_tile
    context.highlighted_tile = highlighted_tile
    context.highlight_zone = highlight_zone


    var interaction: ConstructableData.ConstructableInteraction = DataLoader.constructables[constructable_index].get_interaction(context)
    

    InteractionSingleton.update_interactable(interaction.interaction)

    var target_position = building_tilemap.to_global(building_tilemap.map_to_local(targeted_tile))
    camera.global_position = target_position

    highlight.interp_to(target_position, interaction.color)

    $%EditorSymbolSprite.opacity = interaction.editor_symbol_opacity
    $%EditorSymbolSprite.facing = target_direction
    
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
