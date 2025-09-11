extends Node2D

# Alright, this one is definitely the most complex part of the project
# so it justifies some better documentation.
# This class manages "the automation system" as a whole, which includes
# item movement on belts and into machines.
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
@export var belt_movement_speed: float = 3.0 # tiles per second

var belt_update_timer: float = 0.0

## All items currently managed/registered
var items: Array[Node2D] = []
## Vector2i -> Node2D - the committed positions of items (not based on interpolation)
var item_tile_positions: Dictionary = {}

# This all pertains to the static belt graph and is computed by rescan_belts

## A list of all belt tiles
var belt_tiles: Array[Vector2i] = []
# TODO: Is iterating over this dictionary faster than storing belt_tiles separately?
## Vector2i -> true - A dictionary for a quick membership test
var belt_tiles_set: Dictionary = {}
## Vector2i -> Vector2i - the successor cell for each bellt (it may be a non-belt cell though since belts can feed into machines)
var successor_map: Dictionary = {}

## The registered consumers/machines
## Vector2i -> Node - nodes that can accept items at those tiles
var consumer_map: Dictionary = {}

# All temporary structures reused every tick, just to avoid allocations
# I'm not sure if this is significant in GDScript, but it doesn't hurt

## Vector2i -> int - indegree count for Kahn's algorithm
var _indeg: Dictionary = {}
## Topological order of acyclic nodes for Kahn's algorithm
var _topo: Array[Vector2i] = []
## The queue for Kahn's algorithm
var _queue: Array[Vector2i] = []
## Vector2i -> Vector2i - src -> dest
var _will_move: Dictionary = {}
## Vector2i -> true - destinations reserved this tick
var _reserved: Dictionary = {}
## Vector2i -> true - visited nodes when processing cycles
var _visited_cycle: Dictionary = {}

func _ready():
    # pre-scan belts once at startup
    rescan_belts()

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

## Remove an item from the system and free it. Should be used when machines take items (should we do this outselves?)
func remove_item(item: Node2D) -> void:
    if item.has_meta("tile_pos"):
        var t = item.get_meta("tile_pos")
        item_tile_positions.erase(t)
        item.remove_meta("tile_pos")
    items.erase(item)
    if item.is_inside_tree():
        item.queue_free()

#################### The Actual Simulation Wow

## Plan and commit a belt step. This doesn't interpolate positions, since that happens every update tick
func update_belts() -> void:
    # 1. Copy current occupancy into a dictionary for quick lookup
    var occ: Dictionary = item_tile_positions.duplicate()

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

    # 4. Process acyclic nodes in reverse topological order to plan moves with reservation
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

    # 5. Apply acyclic moves simultaneously
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

    # 6. Process cycles (remaining nodes with _indeg > 0 are cycle nodes)
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

        # Count occupancy using occ AFTER the acyclic moves
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
            
            last_item.set_meta("tile_pos", cycle[0])
            last_item.set_meta("target_pos", automation_tilemap.to_global(automation_tilemap.map_to_local(cycle[0])))
            
            item_tile_positions.erase(cycle[L - 1])
            item_tile_positions[cycle[0]] = last_item
        else:
            # This is a partial cycle, so move occupied runs forward by one if the cell after is empty
            var moves = []
            moves.resize(L)
            for i in range(L):
                moves[i] = false

            var i = 0
            while i < L:
                if not occ.has(cycle[i]):
                    i += 1
                    continue
                var s = i
                var r = 0
                while r < L and occ.has(cycle[(s + r) % L]):
                    r += 1
                var next_idx = (s + r) % L
                if not occ.has(cycle[next_idx]):
                    # mark the whole run to move forward
                    for j in range(r):
                        moves[(s + j) % L] = true
                i = s + r
            
            # Apply moves simultaneously
            var newvals = {}
            
            # Copy current values
            for idx in range(L):
                var ccell = cycle[idx]
                if occ.has(ccell):
                    newvals[ccell] = occ[ccell]
                else:
                    newvals[ccell] = null
            for idx in range(L):
                if moves[idx]:
                    var from = cycle[idx]
                    var to = cycle[(idx + 1) % L]
                    newvals[to] = occ[from]
                    newvals[from] = null
            
            # Commit back to occ and update item metas / manager map
            for idx in range(L):
                var ccell = cycle[idx]
                var val = newvals[ccell]
                if val == null:
                    occ.erase(ccell)
                    item_tile_positions.erase(ccell)
                else:
                    occ[ccell] = val

                    val.set_meta("tile_pos", ccell)
                    val.set_meta("target_pos", automation_tilemap.to_global(automation_tilemap.map_to_local(ccell)))
                    
                    item_tile_positions[ccell] = val

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


#################### Interaction API
# We need to implement everything level_interface relies on since it just treats us as a interactable lol

func get_interaction_position(global_pos: Vector2) -> Vector2i:
    var local_pos = to_local(global_pos)
    return automation_tilemap.local_to_map(local_pos)

func can_interact(cell: Vector2i) -> bool:
    var cell_data: TileData = automation_tilemap.get_cell_tile_data(cell)
    if cell_data == null:
        return false
    
    # TODO: Belt item taking logic idk

    if not PlayerInventorySingleton.has_item():
        return false

    return cell_data.get_custom_data("automation_id") != ""

func interact(cell: Vector2i):
    if not can_interact(cell):
        push_error("Tried to interact with a non-interactable cell: " + str(cell))
        return
    
    var cell_data: TileData = automation_tilemap.get_cell_tile_data(cell)
    var automation_id: String = cell_data.get_custom_data("automation_id")
    match automation_id:
        "up_belt", "down_belt", "left_belt", "right_belt":
            if PlayerInventorySingleton.has_item():
                var item = PlayerInventorySingleton.remove_item()
                register_item(item, cell)
            else:
                push_error("No item to place on belt? hm")
            pass

func get_interact_explanation() -> String:
    return "Place item on belt"

func get_interactable_name() -> String:
    return "Conveyor Belt"

func get_description() -> String:
    return "A conveyor belt that moves items in a set direction.\nPlace an item on the belt to move it along."
