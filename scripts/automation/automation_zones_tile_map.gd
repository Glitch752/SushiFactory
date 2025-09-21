@tool

extends TileMapLayer

# Map from meaning to alternate tile
var alternate_tile_ids: Dictionary[String, int] = {
    "none": 0,
    "counter": 1,
    "reserved": 2,
    "open_for_counter": 3,
    "open": 4,
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
        var has_counter_above = cell_data_above and cell_data_above.get_custom_data("meaning") == "counter"

        if meaning == "reserved" and not has_counter_above:
            set_cell(pos, 0, Vector2i(0, 0), alternate_tile_ids["open"])
            meaning = "open"
        elif meaning != "reserved" and meaning != "counter" and has_counter_above:
            set_cell(pos, 0, Vector2i(0, 0), alternate_tile_ids["reserved"])
            meaning = "reserved"
        
        if meaning == "open" and cell_data_above == null:
            # All open cells with an empty one above have open_for_counter put above
            set_cell(pos + Vector2i.UP, 0, Vector2i(0, 0), alternate_tile_ids["open_for_counter"])
            meaning = "open_for_counter"
