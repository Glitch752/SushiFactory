## The tilemap for automation objects (not really just automation), like counters and belts.
## While this stores the data used for constructing the tilemap, it also serves as a visual representation
## of the objects placed.

extends TileMapLayer

class_name AutomationObjectsTilemap

func _ready():
    visible = false

func show_map():
    visible = true

func hide_map():
    visible = false

func is_counter_at(global_pos: Vector2):
    var data = get_cell_tile_data(local_to_map(to_local(global_pos)))
    return data and data.get_custom_data("is_counter_like")