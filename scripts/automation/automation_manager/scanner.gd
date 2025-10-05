## Rebuild the belt graph from the tilemap.
## This is intentionally an explicit action since it's pretty slow. Call it after editing the tilemap at runtime.
##   TODO: I kind of hate this interface? I mean, we scan belts but not machines which isn't ideal. This was easiest for now, though.
static func scan(mgr: AutomationManager):
    mgr.belt_tiles.clear()
    mgr.belt_tiles_set.clear()
    mgr.successor_map.clear()

    var used_cells = []
    used_cells = mgr.automation_tilemap.get_used_cells()

    # Build belt tile list and successsors
    for cell in used_cells:
        var cell_data = mgr.automation_tilemap.get_cell_tile_data(cell)
        if cell_data == null:
            continue
        var automation_id: String = ""

        automation_id = cell_data.get_custom_data("automation_id")

        var dir = Vector2i.ZERO
        if automation_id == "left_belt":
            dir = Vector2i.LEFT
        elif automation_id == "right_belt":
            dir = Vector2i.RIGHT
        elif automation_id == "up_belt":
            dir = Vector2i.UP
        elif automation_id == "down_belt":
            dir = Vector2i.DOWN
        else:
            continue

        var next_cell = cell + dir
        mgr.belt_tiles.append(cell)
        mgr.belt_tiles_set[cell] = true
        mgr.successor_map[cell] = next_cell

    # pre-allocate indegree structure (not really needed but a bit nicer)
    mgr._indeg.clear()
    for cell in mgr.belt_tiles:
        mgr._indeg[cell] = 0
    

    var underground_entrances: Dictionary[Vector2i, bool] = {} # entrance_pos -> true; just a set
    var underground_exits: Dictionary[Vector2i, Vector2i] = {} # exit_pos -> direction

    # First, collect underground belt tiles
    for cell in used_cells:
        var cell_data = mgr.automation_tilemap.get_cell_tile_data(cell)
        if cell_data == null:
            continue
        
        var automation_id: String = cell_data.get_custom_data("automation_id")
        
        if automation_id.ends_with("_underground_entrance"):
            underground_entrances[cell] = true
            mgr.belt_tiles.append(cell)
            mgr.belt_tiles_set[cell] = true
        elif automation_id.ends_with("_underground_exit"):
            var dir = get_direction_from_id(automation_id)
            underground_exits[cell] = dir
            mgr.belt_tiles.append(cell)
            mgr.belt_tiles_set[cell] = true

    # Second pass: link underground belts
    for entrance in underground_entrances:
        var entrance_data = mgr.automation_tilemap.get_cell_tile_data(entrance)
        var entrance_dir = get_direction_from_id(entrance_data.get_custom_data("automation_id"))
        
        # Find matching exit in the same direction
        var exit_pos = find_underground_exit(entrance, entrance_dir, underground_exits, underground_entrances)
        if exit_pos != Vector2i.ZERO:
            mgr.successor_map[entrance] = exit_pos
            # Exit continues in its direction
            mgr.successor_map[exit_pos] = exit_pos + underground_exits[exit_pos]

static func get_direction_from_id(automation_id: String) -> Vector2i:
    # this is kind of silly but wtv
    if automation_id.begins_with("left_"):
        return Vector2i.LEFT
    elif automation_id.begins_with("right_"):
        return Vector2i.RIGHT
    elif automation_id.begins_with("up_"):
        return Vector2i.UP
    elif automation_id.begins_with("down_"):
        return Vector2i.DOWN
    return Vector2i.ZERO

# There are a few ways we could handle finding the next belt depending on how we want overlap to work.
# e.g. connecting underground belts like >  >  <   <
# could either link 1-3 and 2-4 or 1-4 and 2-3.
# I decided that the latter is more intuitive, so we count the entrances/exits and link once it hits 0.
# This is intuitively consistent regardless of the starting point, but I'm not sure how to prove it for any other strategy lol
static func find_underground_exit(
    entrance: Vector2i,
    direction: Vector2i,
    exits: Dictionary[Vector2i, Vector2i],
    entrances: Dictionary[Vector2i, bool]
) -> Vector2i:
    var current = entrance + direction
    var max_distance = 10

    var entrance_count = 1 # Count ourselves
    
    for i in range(max_distance):
        if exits.has(current) and exits[current] == direction:
            entrance_count -= 1
            if entrance_count == 0:
                return current
        elif entrances.has(current):
            entrance_count += 1
        
        current += direction
    
    return Vector2i.ZERO # mismatched. This shouldn't happen with a well-formed belt structure
