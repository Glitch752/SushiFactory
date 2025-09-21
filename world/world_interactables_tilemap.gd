@tool

extends TileMapLayer

class_name WorldInteractableTilemap

@export var automation_zones_tilemap: TileMapLayer
@onready var interactables: Node2D = $WorldInteractables

var interactable_map: Dictionary[Vector2i, Node2D] = {}

const COUNTER_TILE_SOURCE_ID = 4
const BELT_TILE_SOURCE_ID = 3

const COUNTER_DOWN_ROW = 0
const COUNTER_UP_ROW = 2
const COUNTER_RIGHT_ROW = 4
const COUNTER_LEFT_ROW = 6

const COUNTER_MACHINE_ROWS: Dictionary[String, int] = {
    "down" = 8,
    "up" = 10,
    "right" = 12,
    "left" = 14
}

# Maps from neighbor belts directed into a belt to atlas position
# Key is in the format (back relative to forward, left relative to forward, right relative to forward) and stored as binary.
# The picked belt also depends on if there's a belt in front of this one (facing any direction),
# but those variants are always offset by half the tile map height so we don't need to separately store them.
# We have 4 maps since Godot doesn't support nested collections :(
const UP_BELT_COMBINATIONS: Dictionary[int, Vector2i] = {
    0b000: Vector2i(0, 7 ), # Start of upward belt
    0b001: Vector2i(0, 13), # Left-up corner
    0b010: Vector2i(0, 17), # Right-up corner
    0b011: Vector2i(0, 25), # T-junction (left and right into up)
    0b100: Vector2i(0, 6 ), # Straight up
    0b101: Vector2i(0, 26), # Left and back into up
    0b110: Vector2i(0, 29), # Right and back into up
    0b111: Vector2i(0, 32), # 4-way (left, right, and down into up)
}
const DOWN_BELT_COMBINATIONS: Dictionary[int, Vector2i] = {
    0b000: Vector2i(0, 11), # Start of downward belt
    0b001: Vector2i(0, 19), # Right-down corner
    0b010: Vector2i(0, 15), # Left-down corner
    0b011: Vector2i(0, 22), # T-junction (left and right into down)
    0b100: Vector2i(0, 9 ), # Straight down
    0b101: Vector2i(0, 27), # Right and back into down
    0b110: Vector2i(0, 30), # Left and back into down
    0b111: Vector2i(0, 33), # 4-way (left, right, and up into down)
}
const RIGHT_BELT_COMBINATIONS: Dictionary[int, Vector2i] = {
    0b000: Vector2i(0, 1 ), # Start of rightward belt
    0b001: Vector2i(0, 14), # Up-right corner
    0b010: Vector2i(0, 12), # Down-right corner
    0b011: Vector2i(0, 31), # T-junction (up and down into right)
    0b100: Vector2i(0, 0 ), # Straight right
    0b101: Vector2i(0, 20), # Down and back into right
    0b110: Vector2i(0, 23), # Up and back into right
    0b111: Vector2i(0, 34), # 4-way (up, down, and left into right)
}
const LEFT_BELT_COMBINATIONS: Dictionary[int, Vector2i] = {
    0b000: Vector2i(0, 5 ), # Start of leftward belt
    0b001: Vector2i(0, 16), # Down-left corner
    0b010: Vector2i(0, 18), # Up-left corner
    0b011: Vector2i(0, 28), # T-junction (up and down into left)
    0b100: Vector2i(0, 3 ), # Straight left
    0b101: Vector2i(0, 24), # Up and back into left
    0b110: Vector2i(0, 21), # Down and back into left
    0b111: Vector2i(0, 35), # 4-way (up, down, and right into left)
}

# :( GDScript nested collections when?
const BELT_COMBINATION_MAPS: Dictionary[String, Variant] = {
    "up": UP_BELT_COMBINATIONS,
    "down": DOWN_BELT_COMBINATIONS,
    "right": RIGHT_BELT_COMBINATIONS,
    "left": LEFT_BELT_COMBINATIONS,
}

func _ready():
    # Populate tile map with what's in the world so we can easily set things up in the editor;
    # future changes will be manually handled instead of from scratch
    
    _update_interactable_map()

func _update_interactable_map():
    for child in interactables.get_children():
        interactable_map[_get_tilemap_pos(child.get_node("InteractableContent").global_position)] = child

func _get_tilemap_pos(global_pos: Vector2) -> Vector2i:
    return local_to_map(to_local(global_pos))


@export_tool_button("Rebuild tiles") var rebuild_tiles = _rebuild_tiles

func xnor(a: bool, b: bool) -> bool:
    return (a and b) or (not a and not b)

func _rebuild_tiles():
    var start_time = Time.get_ticks_usec()
    _update_interactable_map()
    var update_interactable_map_time = Time.get_ticks_usec() - start_time

    start_time = Time.get_ticks_usec()

    # Clear all tiles in the automation zones
    var used_cells = automation_zones_tilemap.get_used_cells()
    var used_cell_data: Dictionary[Vector2i, TileData] = {}

    var counter_positions: Array[Vector2i] = []
    var belt_positions: Array[Vector2i]

    for cell in used_cells:
        set_cell(cell, -1)
        var cell_data = automation_zones_tilemap.get_cell_tile_data(cell)
        used_cell_data.set(cell, cell_data)
        if cell_data.get_custom_data("is_counter_like"):
            counter_positions.append(cell)
        if cell_data.get_custom_data("meaning") == "belt":
            belt_positions.append(cell)
    
    # Custom autotiling with code
    for pos in counter_positions:
        var left_data = used_cell_data.get(pos + Vector2i.LEFT)
        var right_data = used_cell_data.get(pos + Vector2i.RIGHT)
        var up_data = used_cell_data.get(pos + Vector2i.UP)

        var counter_left: bool = left_data and left_data.get_custom_data("is_counter_like")
        var counter_right: bool = right_data and right_data.get_custom_data("is_counter_like")
        var counter_up: bool = up_data and up_data.get_custom_data("is_counter_like")

        var cell_data = used_cell_data.get(pos)
        var direction: String = cell_data.get_custom_data("facing")

        var interactable = interactable_map.get(pos)
        var machine = null
        if interactable != null:
            machine = interactable.get("machine")

        if machine != null:
            var tile_x = machine.custom_counter_x
            if tile_x != null and tile_x >= 0:
                set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(tile_x, COUNTER_MACHINE_ROWS[direction]))
                continue
        
        if direction == "down":
            if xnor(counter_left, counter_right):
                var variant = hash(pos + Vector2i(200, 0)) % 2
                set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(variant, COUNTER_DOWN_ROW))
            elif counter_left:
                set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(2, COUNTER_DOWN_ROW))
            else:
                set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(3, COUNTER_DOWN_ROW))
        elif direction == "up":
            if xnor(counter_left, counter_right):
                set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(0, COUNTER_UP_ROW))
            elif counter_left:
                set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(1, COUNTER_UP_ROW))
            else:
                set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(2, COUNTER_UP_ROW))
        elif direction == "right":
            if counter_up and counter_right:
                set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(2, COUNTER_RIGHT_ROW))
            elif counter_right:
                set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(1, COUNTER_RIGHT_ROW))
            else:
                set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(0, COUNTER_RIGHT_ROW))
        elif direction == "left":
            if counter_up and counter_left:
                set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(2, COUNTER_LEFT_ROW))
            elif counter_left:
                set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(1, COUNTER_LEFT_ROW))
            else:
                set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(0, COUNTER_LEFT_ROW))
    
    for pos in belt_positions:
        var up_data = used_cell_data.get(pos + Vector2i.UP)
        var bottom_data = used_cell_data.get(pos + Vector2i.DOWN)
        var left_data = used_cell_data.get(pos + Vector2i.LEFT)
        var right_data = used_cell_data.get(pos + Vector2i.RIGHT)

        var top_facing_into = up_data != null and up_data.get_custom_data("meaning") == "belt" and up_data.get_custom_data("facing") == "down"
        var bottom_facing_into = bottom_data != null and bottom_data.get_custom_data("meaning") == "belt" and bottom_data.get_custom_data("facing") == "up"
        var left_facing_into = left_data != null and left_data.get_custom_data("meaning") == "belt" and left_data.get_custom_data("facing") == "right"
        var right_facing_into = right_data != null and right_data.get_custom_data("meaning") == "belt" and right_data.get_custom_data("facing") == "left"

        var cell_data = used_cell_data.get(pos)
        var direction: String = cell_data.get_custom_data("facing")

        var back: bool = false
        var left: bool = false
        var right: bool = false
        match direction:
            "up":
                back = bottom_facing_into
                left = left_facing_into
                right = right_facing_into
            "down":
                back = top_facing_into
                left = right_facing_into
                right = left_facing_into
            "right":
                back = left_facing_into
                left = top_facing_into
                right = bottom_facing_into
            "left":
                back = right_facing_into
                left = bottom_facing_into
                right = top_facing_into
        
        var atlas_pos = BELT_COMBINATION_MAPS[direction][(int(back) << 2) | (int(left) << 1) | int(right)]
        set_cell(pos, BELT_TILE_SOURCE_ID, atlas_pos)
    
    var rebuild_tiles_time = Time.get_ticks_usec() - start_time
    print_rich("[b]Updated interactable map[/b] in [color=green]%dus[/color] and [b]rebuilt tiles[/b] in [color=green]%dus[/color]" % [update_interactable_map_time, rebuild_tiles_time])