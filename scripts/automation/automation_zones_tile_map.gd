## The automation zones tilemap stores where automation can be built. It's static data, so not updated live.
## The automation objects tilemap stores what's actually built.
## These used to be combined, but it creates much more complex logic for removing objects
## when you need to re-determine what the original restrictions were.

@tool

extends TileMapLayer

class_name AutomationZonesTilemap

# Map from meaning to alternate tile
var alternate_tile_ids: Dictionary[String, int] = {
    "counters_only": 1,
    "open": 2,
    "reserved": 3,
    "selectable_only": 5
}

func _ready():
    if Engine.is_editor_hint():
        return
    
    visible = false

@export_tool_button("Update editor constraints") var update_editor_constraints = _update_editor_constraints

func _update_editor_constraints():
    for pos in get_used_cells():
        var cell_data = get_cell_tile_data(pos)
        var meaning = cell_data.get_custom_data("meaning")

        var cell_data_above = get_cell_tile_data(pos + Vector2i.UP)

        if meaning == "open" and not cell_data_above:
            # All open cells with an empty one above have counters_only put above
            set_cell(pos + Vector2i.UP, 1, Vector2i(0, 0), alternate_tile_ids["counters_only"])
