const BELT_TILE_SOURCE_ID = 0
const BELT_OVERLAY_SOURCE_ID = 5

# TODO: There's some weird autotiling interaction between underground belt starts and belts after them since underground belts are considered "linkable" on their "front" even though that doesn't make sense
# ...and neither does that explanation? future me will figure it out

# Maps from neighbor belts directed into a belt to atlas position
# Key is in the format (back relative to forward, left relative to forward, right relative to forward) and stored as binary.
# The picked belt also depends on if there's a belt in front of this one (facing any direction),
# but those variants are always offset by half the tile map height so we don't need to separately store them.
# We have 4 maps since Godot doesn't support nested collections :(
const UP_BELT_COMBINATIONS: Dictionary[int, Vector2i] = {
    0b000: Vector2i(0, 5 ), # Start of upward belt
    0b001: Vector2i(0, 9 ), # Left-up corner
    0b010: Vector2i(0, 13), # Right-up corner
    0b011: Vector2i(0, 21), # T-junction (left and right into up)
    0b100: Vector2i(0, 4 ), # Straight up
    0b101: Vector2i(0, 25), # Left and back into up
    0b110: Vector2i(0, 22), # Right and back into up
    0b111: Vector2i(0, 28), # 4-way (left, right, and down into up)
}
const DOWN_BELT_COMBINATIONS: Dictionary[int, Vector2i] = {
    0b000: Vector2i(0, 7 ), # Start of downward belt
    0b001: Vector2i(0, 15), # Right-down corner
    0b010: Vector2i(0, 11), # Left-down corner
    0b011: Vector2i(0, 18), # T-junction (left and right into down)
    0b100: Vector2i(0, 6 ), # Straight down
    0b101: Vector2i(0, 23), # Right and back into down
    0b110: Vector2i(0, 26), # Left and back into down
    0b111: Vector2i(0, 29), # 4-way (left, right, and up into down)
}
const RIGHT_BELT_COMBINATIONS: Dictionary[int, Vector2i] = {
    0b000: Vector2i(0, 1 ), # Start of rightward belt
    0b001: Vector2i(0, 10), # Up-right corner
    0b010: Vector2i(0, 8 ), # Down-right corner
    0b011: Vector2i(0, 27), # T-junction (up and down into right)
    0b100: Vector2i(0, 0 ), # Straight right
    0b101: Vector2i(0, 16), # Down and back into right
    0b110: Vector2i(0, 19), # Up and back into right
    0b111: Vector2i(0, 30), # 4-way (up, down, and left into right)
}
const LEFT_BELT_COMBINATIONS: Dictionary[int, Vector2i] = {
    0b000: Vector2i(0, 3 ), # Start of leftward belt
    0b001: Vector2i(0, 12), # Down-left corner
    0b010: Vector2i(0, 14), # Up-left corner
    0b011: Vector2i(0, 24), # T-junction (up and down into left)
    0b100: Vector2i(0, 2 ), # Straight left
    0b101: Vector2i(0, 20), # Up and back into left
    0b110: Vector2i(0, 17), # Down and back into left
    0b111: Vector2i(0, 31), # 4-way (up, down, and right into left)
}

# :( GDScript nested collections when?
const BELT_COMBINATION_MAPS: Dictionary[String, Variant] = {
    "up": UP_BELT_COMBINATIONS,
    "down": DOWN_BELT_COMBINATIONS,
    "right": RIGHT_BELT_COMBINATIONS,
    "left": LEFT_BELT_COMBINATIONS,
}

const BELT_ANIMATION_FRAMES: int = 8

static func update_belt(ctx: AutotileContext):
    var pos = ctx.cell

    var up_data: TileData = ctx.get_cell_tile_data(pos + Vector2i.UP)
    var bottom_data: TileData = ctx.get_cell_tile_data(pos + Vector2i.DOWN)
    var left_data: TileData = ctx.get_cell_tile_data(pos + Vector2i.LEFT)
    var right_data: TileData = ctx.get_cell_tile_data(pos + Vector2i.RIGHT)

    var top_belt = up_data != null and up_data.get_custom_data("connects_to_belt")
    var bottom_belt = bottom_data != null and bottom_data.get_custom_data("connects_to_belt")
    var left_belt = left_data != null and left_data.get_custom_data("connects_to_belt")
    var right_belt = right_data != null and right_data.get_custom_data("connects_to_belt")

    var top_facing_into = top_belt and up_data.get_custom_data("facing") == "down"
    var bottom_facing_into = bottom_belt and bottom_data.get_custom_data("facing") == "up"
    var left_facing_into = left_belt and left_data.get_custom_data("facing") == "right"
    var right_facing_into = right_belt and right_data.get_custom_data("facing") == "left"

    var direction: String = ctx.cell_data.get_custom_data("facing")

    var back: bool = false
    var left: bool = false
    var right: bool = false
    var front: bool = false
    match direction:
        "up":
            back = bottom_facing_into
            left = left_facing_into
            right = right_facing_into
            front = top_belt
        "down":
            back = top_facing_into
            left = right_facing_into
            right = left_facing_into
            front = bottom_belt
        "right":
            back = left_facing_into
            left = top_facing_into
            right = bottom_facing_into
            front = right_belt
        "left":
            back = right_facing_into
            left = bottom_facing_into
            right = top_facing_into
            front = left_belt
    
    var atlas_pos = BELT_COMBINATION_MAPS[direction][(int(back) << 2) | (int(left) << 1) | int(right)]
    if not front:
        atlas_pos.x += BELT_ANIMATION_FRAMES
    
    ctx.set_underlayer_cell(pos, BELT_TILE_SOURCE_ID, atlas_pos)

const ENTRANCE_UNDERGROUND_BELTS: Dictionary[String, Vector2i] = {
    "right": Vector2i(0, 32),
    "left": Vector2i(0, 34),
    "up": Vector2i(0, 36),
    "down": Vector2i(0, 39)
}
const EXIT_UNDERGROUND_BELTS: Dictionary[String, Vector2i] = {
    "right": Vector2i(0, 35),
    "left": Vector2i(0, 33),
    "up": Vector2i(0, 38),
    "down": Vector2i(0, 37)
}

const ENTRANCE_UNDERGROUND_BELT_OVERLAYS: Dictionary[String, Vector2i] = {
    "right": Vector2i(0, 0),
    "left": Vector2i(2, 0),
    "up": Vector2i(4, 0),
    "down": Vector2i(7, 0)
}
const EXIT_UNDERGROUND_BELT_OVERLAYS: Dictionary[String, Vector2i] = {
    "right": Vector2i(3, 0),
    "left": Vector2i(1, 0),
    "up": Vector2i(6, 0),
    "down": Vector2i(5, 0)
}

const FRONT_DIRECTIONS: Dictionary[String, Vector2i] = {
    "up": Vector2i.UP,
    "down": Vector2i.DOWN,
    "right": Vector2i.RIGHT,
    "left": Vector2i.LEFT
}

static func update_underground_entrance(ctx: AutotileContext):
    var direction: String = ctx.cell_data.get_custom_data("facing")
    var atlas_pos = ENTRANCE_UNDERGROUND_BELTS[direction]
    var back_data = ctx.get_cell_tile_data(ctx.cell - FRONT_DIRECTIONS[direction])
    if not back_data or not back_data.get_custom_data("connects_to_belt"):
        atlas_pos.x += BELT_ANIMATION_FRAMES
    ctx.set_underlayer_cell(ctx.cell, BELT_TILE_SOURCE_ID, atlas_pos)

    var overlay_atlas_pos = ENTRANCE_UNDERGROUND_BELT_OVERLAYS[direction]
    ctx.set_cell(ctx.cell, BELT_OVERLAY_SOURCE_ID, overlay_atlas_pos, 0)
    
static func update_underground_exit(ctx: AutotileContext):
    var direction: String = ctx.cell_data.get_custom_data("facing")
    var atlas_pos = EXIT_UNDERGROUND_BELTS[direction]
    var front_data = ctx.get_cell_tile_data(ctx.cell + FRONT_DIRECTIONS[direction])
    if not front_data or not front_data.get_custom_data("connects_to_belt"):
        atlas_pos.x += BELT_ANIMATION_FRAMES
    ctx.set_underlayer_cell(ctx.cell, BELT_TILE_SOURCE_ID, atlas_pos)

    var overlay_atlas_pos = EXIT_UNDERGROUND_BELT_OVERLAYS[direction]
    ctx.set_cell(ctx.cell, BELT_OVERLAY_SOURCE_ID, overlay_atlas_pos, 0)
