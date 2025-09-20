@tool

extends TileMapLayer

class_name WorldInteractableTilemap

@export var automation_zones_tilemap: TileMapLayer
@onready var interactables: Node2D = $WorldInteractables

var interactable_map: Dictionary[Vector2i, Node2D] = {}

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
    print("Rebuilding")