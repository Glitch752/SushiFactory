@tool

extends TileMapLayer

class_name WorldInteractableTilemap

@export var automation_zones_tilemap: TileMapLayer
@onready var interactables: Node2D = $WorldInteractables

var interactable_map: Dictionary[Vector2i, Node2D] = {}

const COUNTER_TILE_SOURCE_ID = 4

func _ready():
    # Populate tile map with what's in the world so we can easily set things up in the editor;
    # future changes will be manually handled instead of from scratch
    
    _update_interactable_map()

func _update_interactable_map():
    for child in interactables.get_children():
        interactable_map[_get_tilemap_pos(child.global_position)] = child

func _get_tilemap_pos(global_pos: Vector2) -> Vector2i:
    return local_to_map(to_local(global_pos))


@export_tool_button("Rebuild tiles") var rebuild_tiles = _rebuild_tiles

func _rebuild_tiles():
    _update_interactable_map()

    # Clear all tiles in the automation zones
    var used_cells = automation_zones_tilemap.get_used_cells()
    var used_cell_meanings: Dictionary[Vector2i, String] = {}

    var counter_positions: Array[Vector2i] = []
    for cell in used_cells:
        set_cell(cell, -1)
        var meaning = automation_zones_tilemap.get_cell_tile_data(cell).get_custom_data("meaning")
        used_cell_meanings.set(cell, meaning)
        if meaning == "counter":
            counter_positions.append(cell)
    
    # Custom autotiling with code
    for pos in counter_positions:
        var counter_left = used_cell_meanings.get(pos + Vector2i.LEFT) == "counter"
        var counter_right = used_cell_meanings.get(pos + Vector2i.RIGHT) == "counter"
        var counter_up = used_cell_meanings.get(pos + Vector2i.UP) == "counter"
        var counter_down = used_cell_meanings.get(pos + Vector2i.DOWN) == "counter"

        if used_cell_meanings[pos] == "counter":
            set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(1, 0))