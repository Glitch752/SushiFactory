const COUNTER_TILE_SOURCE_ID = 4

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

static func update_counter(ctx: AutotileContext):
    var pos = ctx.cell

    var up_data: TileData = ctx.get_cell_tile_data(pos + Vector2i.UP)
    var left_data: TileData = ctx.get_cell_tile_data(pos + Vector2i.LEFT)
    var right_data: TileData = ctx.get_cell_tile_data(pos + Vector2i.RIGHT)

    var counter_left: bool = left_data and left_data.get_custom_data("is_counter_like")
    var counter_right: bool = right_data and right_data.get_custom_data("is_counter_like")
    var counter_up: bool = up_data and up_data.get_custom_data("is_counter_like")

    var left_facing = left_data.get_custom_data("facing") if left_data else ""
    var right_facing = right_data.get_custom_data("facing") if right_data else ""

    var direction: String = ctx.cell_data.get_custom_data("facing")

    var machine = null
    if ctx.interactable != null:
        machine = ctx.interactable.get("machine")

    if machine != null:
        var tile_x = machine.custom_counter_x
        if tile_x != null and tile_x >= 0:
            ctx.set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(tile_x, COUNTER_MACHINE_ROWS[direction]))
            return
    
    if direction == "down":
        var compatible_counter_left = counter_left and (left_facing == "down" or left_facing == "right")
        var compatible_counter_right = counter_right and (right_facing == "down" or right_facing == "left")
        if not (compatible_counter_left or compatible_counter_right):
            ctx.set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(4, COUNTER_DOWN_ROW))
        elif compatible_counter_left and compatible_counter_right:
            var variant = hash(pos + Vector2i(200, 0)) % 2
            ctx.set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(variant, COUNTER_DOWN_ROW))
        elif compatible_counter_left:
            ctx.set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(2, COUNTER_DOWN_ROW))
        else:
            ctx.set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(3, COUNTER_DOWN_ROW))
    elif direction == "up":
        var compatible_counter_left = counter_left and (left_facing == "up" or left_facing == "right")
        var compatible_counter_right = counter_right and (right_facing == "up" or right_facing == "left")
        if not (compatible_counter_left or compatible_counter_right):
            ctx.set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(3, COUNTER_UP_ROW))
        elif compatible_counter_left and compatible_counter_right:
            ctx.set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(0, COUNTER_UP_ROW))
        elif compatible_counter_left:
            ctx.set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(1, COUNTER_UP_ROW))
        else:
            ctx.set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(2, COUNTER_UP_ROW))
    elif direction == "right":
        var counter_right_facing_down = counter_right and right_facing == "down"
        var counter_right_facing_up = counter_right and right_facing == "up"
        if counter_up and counter_right_facing_down:
            ctx.set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(2, COUNTER_RIGHT_ROW))
        elif counter_right_facing_up:
            ctx.set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(3, COUNTER_RIGHT_ROW))
        elif counter_right_facing_down:
            ctx.set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(1, COUNTER_RIGHT_ROW))
        else:
            ctx.set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(0, COUNTER_RIGHT_ROW))
    elif direction == "left":
        var counter_left_facing_down = counter_left and left_facing == "down"
        var counter_left_facing_up = counter_left and left_facing == "up"
        if counter_up and counter_left_facing_down:
            ctx.set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(2, COUNTER_LEFT_ROW))
        elif counter_left_facing_up:
            ctx.set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(3, COUNTER_LEFT_ROW))
        elif counter_left_facing_down:
            ctx.set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(1, COUNTER_LEFT_ROW))
        else:
            ctx.set_cell(pos, COUNTER_TILE_SOURCE_ID, Vector2i(0, COUNTER_LEFT_ROW))
