@tool

extends TileMapLayer

# Map from meaning to alternate tile
var alternate_tile_ids: Dictionary[String, int] = {
    "none": 0,
    "open": 1,
    "reserved": 2,
    "counter": 3
}

func _ready():
    if Engine.is_editor_hint():
        return
    
    visible = false

@export_tool_button("Update editor constraints") var update_editor_constraints = _update_editor_constraints

func _update_editor_constraints():
    print("ahahhhhh")

    for pos in get_used_cells():
        var cell_data = get_cell_tile_data(pos)
        var meaning = cell_data.get_custom_data("meaning")

        var cell_data_above = get_cell_tile_data(pos + Vector2i.UP)
        var has_counter_above = cell_data_above and cell_data_above.get_custom_data("meaning") == "counter"

        if meaning == "reserved" and not has_counter_above:
            set_cell(pos, 0, Vector2i(0, 0), alternate_tile_ids["open"])
        elif meaning == "open" and has_counter_above:
            set_cell(pos, 0, Vector2i(0, 0), alternate_tile_ids["reserved"])
