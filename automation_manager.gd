extends Node2D

# Must implement the same interface as Interactable for LevelInterface, though this isn't an interactable

@export var automation_tilemap: TileMapLayer

## Speed at which the conveyor belt moves items in tiles per second.
@export var belt_movement_speed: float = 3

var belt_update_timer: float = 0.0

var items: Array[Node2D] = []

var item_tile_positions: Dictionary = {} # Vector2i -> Node2D

func _physics_process(delta):
    # Check if we should update belts
    belt_update_timer += delta
    if belt_update_timer >= 1.0 / belt_movement_speed:
        belt_update_timer -= floor(belt_update_timer * belt_movement_speed) / belt_movement_speed
        update_belts()
    
    update_item_interpolation(delta)

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
                add_item(item, cell)
            else:
                push_error("No item to place on belt? hm")
            pass


func update_belts():
    for item in items:
        var cell: Vector2i = automation_tilemap.local_to_map(automation_tilemap.to_local(item.global_position))
        var cell_data = automation_tilemap.get_cell_tile_data(cell)
        if cell_data == null:
            continue
        
        var automation_id: String = cell_data.get_custom_data("automation_id")
        if automation_id == "":
            continue
        
        var direction: Vector2i = Vector2i.ZERO
        if automation_id == "left_belt":
            direction = Vector2i.LEFT
        elif automation_id == "right_belt":
            direction = Vector2i.RIGHT
        elif automation_id == "up_belt":
            direction = Vector2i.UP
        elif automation_id == "down_belt":
            direction = Vector2i.DOWN
        else:
            continue
        
        var next_cell = cell + direction

        if item_tile_positions.has(next_cell):
            # Next cell is occupied
            continue
        
        var next_cell_data = automation_tilemap.get_cell_tile_data(next_cell)
        if next_cell_data == null or next_cell_data.get_custom_data("automation_id") == "":
            continue
        
        smoothly_move_item_to(item, next_cell)

func smoothly_move_item_to(item: Node2D, cell: Vector2i):
    item_tile_positions.erase(item.get_meta("tile_pos"))
    item.set_meta("target_pos", automation_tilemap.to_global(automation_tilemap.map_to_local(cell)))
    item.set_meta("tile_pos", cell)
    item_tile_positions[cell] = item

func update_item_interpolation(delta: float):
    for item in items:
        if item.has_meta("target_pos"):
            var target_pos: Vector2 = item.get_meta("target_pos")
            # kinda hacky but meh
            var new_pos = item.global_position.move_toward(target_pos, belt_movement_speed * delta * automation_tilemap.tile_set.tile_size.x)
            item.global_position = new_pos

func add_item(item: Node2D, cell: Vector2i):
    if item.is_inside_tree():
        item.get_parent().remove_child(item)

    items.append(item)
    add_child(item)

    item_tile_positions[cell] = item
    item.global_position = automation_tilemap.to_global(automation_tilemap.map_to_local(cell))

func get_interact_explanation() -> String:
    return "Place item on belt"

func get_interactable_name() -> String:
    return "Conveyor Belt"

func get_description() -> String:
    return "A conveyor belt that moves items in a set direction.\nPlace an item on the belt to move it along."
