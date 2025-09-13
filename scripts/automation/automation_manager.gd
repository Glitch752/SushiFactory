extends Node2D

# Alright, this one is definitely the most complex part of the project so it justifies some better documentation.
# This class manages "the automation system" as a whole, which includes item movement on belts and into machines.
# If I actually implemented it properly based on the implementations I referenced, it should run in O(belt tiles) per simulation tick.
# Because it uses a graph implementation, it supports simultaneous move planning without overlaps e.g. a circle of belts that all have items will move as expected.
# Furthermore, this allows it to handle chains, merges where multiple belts go into one, and full loops.
# Then, there are "consumers" e.g. machines that can accept items at specific tiles.
#
# Usage required outside this class:
# - The player and some other entities expect the automation manager to be on a Node2D in the current level with a unique name of "AutomationManager".
#   There's probably a way to avoid this, like using singletons? This is easiest, though.
# - automation_tilemap must point to the tilemap that contains belt tiles
# - Call register_item(item_node, cell) to add items to the system
# - Consumers register themselves with register_consumer(cell, node) and implement `func try_accept_item(item: Node2D) -> bool`
#   which must return true if the machine accepts the item and take ownership/handle of it (e.g. queue it, reparent it, whatever).
#   For now, machines need to call `remove_item(item)` themselves when they take an item.
# - Call rescan_belts() when the tilemap layout changes

@export var automation_tilemap: TileMapLayer
@export var belt_movement_speed: float = 3.8 # tiles per second

var belt_update_timer: float = 0.0

## All items currently managed/registered
var items: Array[Node2D] = []
## The committed positions of items (not based on interpolation)
var item_tile_positions: Dictionary[Vector2i, Node2D] = {}

# This all pertains to the static belt graph and is computed by rescan_belts

## A list of all belt tiles
var belt_tiles: Array[Vector2i] = []
# TODO: Is iterating over this dictionary faster than storing belt_tiles separately?
## A dictionary for a quick membership test. All values are true.
var belt_tiles_set: Dictionary[Vector2i, bool] = {}
## The successor cell for each bellt (it may be a non-belt cell though since belts can feed into machines)
var successor_map: Dictionary[Vector2i, Vector2i] = {}

## The registered consumers/machines
## Nodes that can accept items at those tiles
var consumer_map: Dictionary[Vector2i, Node] = {}

# All temporary structures reused every tick, just to avoid allocations
# I'm not sure if this is significant in GDScript, but it doesn't hurt

## Indegree count for Kahn's algorithm
var _indeg: Dictionary[Vector2i, int] = {}
## Topological order of acyclic nodes for Kahn's algorithm
var _topo: Array[Vector2i] = []
## The queue for Kahn's algorithm
var _queue: Array[Vector2i] = []
## src -> dest
var _will_move: Dictionary[Vector2i, Vector2i] = {}
## Destinations reserved this tick. All values are true.
var _reserved: Dictionary[Vector2i, bool] = {}
## Visited nodes when processing cycles. All values are true.
var _visited_cycle: Dictionary[Vector2i, bool] = {}

signal belts_updated()

func _ready():
    # pre-scan belts once at startup
    rescan_belts()
    set_process(false)

func _physics_process(delta: float) -> void:
    belt_update_timer += delta
    var tick_interval = 1.0 / max(0.0001, belt_movement_speed)
    if belt_update_timer >= tick_interval:
        # avoid drift: subtract an integer number of ticks
        var ticks = floor(belt_update_timer / tick_interval)
        belt_update_timer -= ticks * tick_interval
        # run that many ticks (usually 1)
        for i in range(int(ticks)):
            update_belts()
        belts_updated.emit()

    update_item_interpolation(delta)

#################### Public API

## Rebuild the belt graph from the tilemap.
## This is intentionally an explicit action since it's pretty slow. Call it after editing the tilemap at runtime.
##   TODO: I kind of hate this interface? I mean, we scan belts but not machines which isn't ideal. This was easiest for now, though.
func rescan_belts() -> void:
    belt_tiles.clear()
    belt_tiles_set.clear()
    successor_map.clear()

    var used_cells = []
    used_cells = automation_tilemap.get_used_cells()

    # Build belt tile list and successsors
    for cell in used_cells:
        var cell_data = automation_tilemap.get_cell_tile_data(cell)
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
        belt_tiles.append(cell)
        belt_tiles_set[cell] = true
        successor_map[cell] = next_cell

    # pre-allocate indegree structure (not strictly needed but a bit nicer)
    _indeg.clear()
    for cell in belt_tiles:
        _indeg[cell] = 0

## Register a node (machine/consumer) that sits at tile `cell`.
## The node must implement `func try_accept_item(item: Node2D) -> bool`
func register_consumer(cell: Vector2i, node: Node) -> void:
    consumer_map[cell] = node

## Unregister a consumer/machine at tile `cell`
func unregister_consumer(cell: Vector2i) -> void:
    consumer_map.erase(cell)

## Add an item to the system and snap it to the provided cell.
func register_item(item: Node2D, cell: Vector2i) -> void:
    if item.is_inside_tree():
        item.get_parent().remove_child(item)
    items.append(item)
    add_child(item)

    item_tile_positions[cell] = item
    item.set_meta("tile_pos", cell)
    # set immediate world position to cell
    item.global_position = automation_tilemap.to_global(automation_tilemap.map_to_local(cell))
    # ensure no leftover interpolation meta
    if item.has_meta("target_pos"):
        item.remove_meta("target_pos")

## Remove an item from the system (but don't free it). Should be used when machines take items (should we do this outselves?)
func remove_item(item: Node2D) -> void:
    if item.has_meta("tile_pos"):
        var t = item.get_meta("tile_pos")
        item_tile_positions.erase(t)
        item.remove_meta("tile_pos")
    items.erase(item)

    remove_child(item)

#################### The Actual Simulation Wow

## Plan and commit a belt step. This doesn't interpolate positions, since that happens every update tick
func update_belts() -> void:
    # 1. Copy current occupancy into a dictionary for quick lookup
    var occ: Dictionary[Vector2i, Node2D] = item_tile_positions.duplicate()

    # 2. Compute indegree for the belt graph (only counts edges between belt tiles, not to consumers/sinks)
    _indeg.clear()
    for cell in belt_tiles:
        _indeg[cell] = 0
    for u in belt_tiles:
        var v = successor_map.get(u, null)
        if v != null and belt_tiles_set.has(v):
            _indeg[v] = _indeg.get(v, 0) + 1

    # 3. Kahn to separate acyclic nodes (topological order) and cyclic nodes
    _topo.clear()
    _queue.clear()
    for u in belt_tiles:
        if _indeg.get(u, 0) == 0:
            _queue.append(u)

    while _queue.size() > 0:
        var u = _queue.pop_back()
        _topo.append(u)
        var v = successor_map.get(u, null)
        if v != null and belt_tiles_set.has(v):
            _indeg[v] = _indeg.get(v, 0) - 1
            if _indeg[v] == 0:
                _queue.append(v)

    # After the loop, nodes where _indeg > 0 form cycles

    # 4. Process cycles
    _visited_cycle.clear()
    for u in belt_tiles:
        if _indeg.get(u, 0) <= 0:
            continue
        if _visited_cycle.has(u):
            continue
        
        # Build the cycle in order
        var cycle = []
        var w = u
        while not _visited_cycle.has(w):
            cycle.append(w)
            _visited_cycle[w] = true
            w = successor_map.get(w, null)
            # w should always be valid in a well-formed cycle
        if cycle.size() == 0:
            continue

        var L = cycle.size()

        # Count the occupied cell count to determine if we have a full cycle or partial
        var k = 0
        for c in cycle:
            if occ.has(c):
                k += 1
        if k == 0:
            continue

        if k == L:
            # This is a fully occupied cycle, so we rotate all items forward by one
            var last_item = occ[cycle[L - 1]]
            for i in range(L - 1, 0, -1):
                var from = cycle[i - 1]
                var to = cycle[i]
                occ[to] = occ[from]
                
                var moved_item = occ[to]
                
                moved_item.set_meta("tile_pos", to)
                moved_item.set_meta("target_pos", automation_tilemap.to_global(automation_tilemap.map_to_local(to)))
                
                item_tile_positions.erase(from)
                item_tile_positions[to] = moved_item
            occ[cycle[0]] = last_item

            var moved_first_item = occ[cycle[0]]
            moved_first_item.set_meta("tile_pos", cycle[0])
            moved_first_item.set_meta("target_pos", automation_tilemap.to_global(automation_tilemap.map_to_local(cycle[0])))
            item_tile_positions[cycle[0]] = moved_first_item
        else:
            # This is a partial cycle, so move occupied runs forward by one if the cell after is empty
            var extended_cycle = cycle.duplicate()
            extended_cycle.append(cycle[0]) # wrap around for easier handling of end case
            var start = -1

            for i in range(L):
                var c = extended_cycle[i]
                if occ.has(c) and start == -1:
                    start = i
                elif not occ.has(c) and start != -1:
                    # We found a run from start to i-1 (inclusive) that can move forward
                    for j in range(i - 1, start - 1, -1):
                        var from = extended_cycle[j]
                        var to = extended_cycle[j + 1]
                        occ[to] = occ[from]
                        var moved_item = occ[to]
                        
                        moved_item.set_meta("tile_pos", to)
                        moved_item.set_meta("target_pos", automation_tilemap.to_global(automation_tilemap.map_to_local(to)))
                        
                        item_tile_positions.erase(from)
                        item_tile_positions[to] = moved_item
                    occ.erase(extended_cycle[start])
                    start = -1
            
            # If we ended with a run, it wraps around
            if start != -1:
                for j in range(L - 1, start - 1, -1):
                    var from = extended_cycle[j]
                    var to = extended_cycle[j + 1]
                    occ[to] = occ[from]
                    var moved_item = occ[to]
                    
                    moved_item.set_meta("tile_pos", to)
                    moved_item.set_meta("target_pos", automation_tilemap.to_global(automation_tilemap.map_to_local(to)))
                    
                    item_tile_positions.erase(from)
                    item_tile_positions[to] = moved_item
                occ.erase(extended_cycle[start])

    # 5. Process acyclic nodes in reverse topological order to plan moves with reservation
    _will_move.clear()
    _reserved.clear()

    # Because we want deterministic tie-breaking at merges, we need to iterate in reverse order
    for i in range(_topo.size() - 1, -1, -1):
        var u = _topo[i]
        if not occ.has(u):
            continue
        var item = occ[u]
        var v = successor_map.get(u, null)
        if v == null:
            # Shouldn't happen, but if there's no successor just don't move
            if not _reserved.has(v):
                _reserved[v] = true
                _will_move[u] = v
            continue
        
        if belt_tiles_set.has(v):
            # If v is a belt tile
            # If the destination is empty, let one and only one predecessor move onto it
            if not occ.has(v):
                if not _reserved.has(v):
                    _reserved[v] = true
                    _will_move[u] = v
            else:
                # The destination occupied
                # Allow the move only if the occupant at v will move away
                # we already decided the final moves for v since it's later in topological order
                if _will_move.has(v) and not _reserved.has(v):
                    _reserved[v] = true
                    _will_move[u] = v
        else:
            # The destination isn't a belt tile: it's either a machine/consumer or an output/drop
            var consumer = consumer_map.get(v, null)
            if consumer != null:
                # Ask the consumer if it accepts this specific item now
                # The consumer must implement try_accept_item(item) -> bool.
                if consumer.try_accept_item(item):
                    # The consumer accepted the item, so reserve it for this tick
                    if not _reserved.has(v):
                        _reserved[v] = true
                        _will_move[u] = v
                    # else:
                        # If consumer already reserved by earlier predecessor this tick, it rejected us
                        # consumer.try_accept_item was already called
                        # pass
                # else:
                    # consumer refused -> cannot move
                    # pass
            else:
                # There isn't a consumer here, so this is an output/drop
                # Allow exactly one item to fall out
                if not _reserved.has(v):
                    _reserved[v] = true
                    _will_move[u] = v

    # 6. Apply acyclic moves simultaneously
    # We mutate occ and item_tile_positions accordingly and set target_pos on items for interpolation
    for src in _will_move.keys():
        var dst = _will_move[src]
        var item = occ.get(src, null)

        # If dst is a belt tile, move onto the belt
        if dst != null and belt_tiles_set.has(dst):
            occ.erase(src)
            occ[dst] = item
            
            item.set_meta("tile_pos", dst)
            item.set_meta("target_pos", automation_tilemap.to_global(automation_tilemap.map_to_local(dst)))
            
            # Update our internal mapping
            item_tile_positions.erase(src)
            item_tile_positions[dst] = item
        else:
            # dst is sink, consumer, or drop
            var consumer = consumer_map.get(dst, null)
            var accepted = false
            if consumer != null:
                # We already asked consumer earlier in planning step, so just call it again to transfer ownership
                # TODO: This is like a major oversight and I should switch to a transactional mechanism like
                # can_accept_item or storing a queue of pending items to accept
                accepted = consumer.try_accept_item(item)
            
            if accepted:
                # consumer took ownership; remove item from belt system
                item_tile_positions.erase(src)
                items.erase(item)
                occ.erase(src)
                # The consumer is responsible for reparenting / queue_free / etc
            else:
                # No consumer: drop item off the belt
                # TODO: Better behavior here to prevent infinite items from stacking up on the ground
                item_tile_positions.erase(src)
                items.erase(item)
                occ.erase(src)
                if item.is_inside_tree():
                    item.queue_free()

    # Yay!

#################### Interpolation

## Moves items smoothly toward their target_pos meta if set
func update_item_interpolation(delta: float) -> void:
    var tile_world_size = automation_tilemap.tile_set.tile_size
    var step = belt_movement_speed * delta * tile_world_size.x # Meh just take the x axis, our tiles are square

    for item in items.duplicate():
        if not item.has_meta("target_pos"):
            continue
        
        var target_pos: Vector2 = item.get_meta("target_pos")
        
        # move_toward handles small steps, so we don't need to special case snapping
        var new_pos = item.global_position.move_toward(target_pos, step)
        item.global_position = new_pos

    # # FOR DEBUGGING: use the tile_pos instead to show discrete positions
    # for item in items.duplicate():
    #     if not item.has_meta("tile_pos"):
    #         continue
    #     var tile_pos: Vector2i = item.get_meta("tile_pos")
    #     item.global_position = automation_tilemap.to_global(automation_tilemap.map_to_local(tile_pos))


#################### Interaction API

const InteractionData = preload("res://world/interactable/interactable.gd").InteractionData
const InteractionAction = preload("res://world/interactable/interactable.gd").InteractionAction

func get_interaction_cell(global_pos: Vector2) -> Vector2i:
    return automation_tilemap.local_to_map(automation_tilemap.to_local(global_pos))

func get_cell_center(cell: Vector2i) -> Vector2:
    return automation_tilemap.to_global(automation_tilemap.map_to_local(cell))

func get_interaction_data(cell: Vector2i) -> InteractionData:
    if not belt_tiles_set.has(cell):
        return null
    
    var has_item = item_tile_positions.has(cell)
    var action: InteractionAction = null
    if has_item:
        if not PlayerInventorySingleton.has_item():
            action = InteractionAction.new("Take item", func(): take_item_from_belt(cell))
    else:
        if PlayerInventorySingleton.has_item():
            action = InteractionAction.new("Place item", func(): add_item_to_belt(cell))
    
    var interactable_name = "Conveyor Belt"

    var direction = ""
    var cell_data = automation_tilemap.get_cell_tile_data(cell)
    if cell_data != null:
        var automation_id: String = cell_data.get_custom_data("automation_id")
        match automation_id:
            "left_belt":
                direction = "left"
            "right_belt":
                direction = "right"
            "up_belt":
                direction = "up"
            "down_belt":
                direction = "down"
    
    var desc = "A belt that moves items %s." % direction
    if has_item:
        desc += "\nCurrently has %s on it." % item_tile_positions[cell].data.item_name
    else:
        desc += "\nCurrently empty."
    
    return InteractionData.new(interactable_name, desc, action)

func add_item_to_belt(cell: Vector2i) -> void:
    if not belt_tiles_set.has(cell):
        return
    if item_tile_positions.has(cell):
        return
    if not PlayerInventorySingleton.has_item():
        return
    
    var item = PlayerInventorySingleton.remove_item()
    register_item(item, cell)

func take_item_from_belt(cell: Vector2i) -> void:
    if not belt_tiles_set.has(cell):
        return
    if not item_tile_positions.has(cell):
        return
    if PlayerInventorySingleton.has_item():
        return
    
    var item = item_tile_positions[cell]
    remove_item(item)
    PlayerInventorySingleton.try_grab_item(item)

## Take a plate with the specified item on it near the provided global position in a 3x3 area. Used for
## customers "taking" items off the sushi belt.
func take_item_on_plate_near(global_pos: Vector2, item_id: String) -> Node2D:
    var cell = get_interaction_cell(global_pos)
    # Check the 3x3 area centered at cell
    for dx in range(-1, 2):
        for dy in range(-1, 2):
            var check_cell = cell + Vector2i(dx, dy)
            if item_tile_positions.has(check_cell):
                var plate = item_tile_positions[check_cell]
                if plate and plate.data.id == "plate" and plate.has_item(item_id):
                    remove_item(plate)
                    return plate
    return null


#################### Debug drawing

var debug_annotations: bool = false

# func _input(event):
#     if event is InputEventKey and event.pressed and not event.echo:
#         # Temporary: when pressing 0, debug draw
#         if event.keycode == KEY_0:
#             debug_annotations = not debug_annotations
#             set_process(debug_annotations)
#             queue_redraw()

func _process(_delta):
    if debug_annotations:
        queue_redraw()

func _draw():
    if not debug_annotations:
        return
    
    var tile_world_size = Vector2(automation_tilemap.tile_set.tile_size)

    # Draw an arrow at every belt in blue if it's acyclic or orange if it's cyclic
    for cell in belt_tiles:
        var start = to_local(automation_tilemap.to_global(automation_tilemap.map_to_local(cell)))
        var end = to_local(automation_tilemap.to_global(automation_tilemap.map_to_local(successor_map[cell])))
        
        var dir = (end - start).normalized()
        start += dir * (tile_world_size.x * 0.2)
        end -= dir * (tile_world_size.x * 0.2)

        var color = Color.LIGHT_BLUE
        if _indeg.get(cell, 0) > 0:
            color = Color.LIGHT_GREEN
        
        draw_line(start, end, color, 1.0)
        var perp = Vector2(-dir.y, dir.x) * 3
        draw_line(end, end - dir * 5 + perp, color, 1.0)
        draw_line(end, end - dir * 5 - perp, color, 1.0)
    
    var inset = Vector2.ONE * 2
    
    # Draw a red square around every occupied tile
    for cell in item_tile_positions.keys():
        var top_left = to_local(automation_tilemap.to_global(automation_tilemap.map_to_local(cell)) - tile_world_size / 2)
        draw_rect(Rect2(top_left + inset, tile_world_size - inset * 2), Color(1, 0, 0, 0.5))
    
    # Draw a green square around every consumer
    for cell in consumer_map.keys():
        var top_left = to_local(automation_tilemap.to_global(automation_tilemap.map_to_local(cell)) - tile_world_size / 2)
        draw_rect(Rect2(top_left + inset, tile_world_size - inset * 2), Color(0, 1, 0, 0.5))
