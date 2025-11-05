extends Node

var held_item_index: int = 0
var inventory_items: Array[Node2D] = []

var held_item:
    get:
        return inventory_items[held_item_index]
    set(value):
        inventory_items[held_item_index] = value

const SLOT_COUNT = 1

func _ready():
    for i in SLOT_COUNT:
        inventory_items.append(null)

func _play_reset() -> void:
    inventory_items.clear()
    _ready()

func all_inventory_items() -> Array[Node2D]:
    return inventory_items

signal items_changed(items: Array[Node2D], held_item_index: int)

## Should only be connected to by the object that wants to hold our current item, e.g. the player's carried item manager.
## Must reset the position of the item after reparenting.
## This probably isn't the best way to structure this, but meh
signal item_scene_reparent(item: Node2D)

var ItemScene = preload("res://world/items/item.tscn")

func create_item(data: ItemData) -> Node2D:
    var item: Node2D

    if data.custom_scene:
        item = data.custom_scene.instantiate()
    else:
        item = ItemScene.instantiate()

    item.data = data
    item.apply_data()

    return item

func has_item() -> bool:
    return held_item != null

func holding_item(id: StringName) -> bool:
    return has_item() and held_item.data.id == id

func held_item_data() -> ItemData:
    if has_item():
        return held_item.data
    return null

func switch_slot(dir: int):
    # If we currently have an item -- meaning it's parented to wherever -- send it to the aether (i'm running on like 4hrs of sleep help me)
    if has_item():
        ## Don't free the item! Just remove it.
        held_item.get_parent().remove_child(held_item)

    held_item_index = (held_item_index + dir) % SLOT_COUNT
    items_changed.emit(inventory_items, held_item_index)
    
    if held_item != null:
        # Ensure the item is inside the tree
        if not held_item.is_inside_tree():
            get_tree().current_scene.add_child(held_item)
        
        item_scene_reparent.emit(held_item)

## Tries to grab the given item.
## If the item is in the scene, it will be reparented to the player.
## This will play a sound for taking the item as long as it's already in the tree.
## Even if you just created an item, you should add it to the tree in a location that makes
## sense so sounds play correctly.
func try_grab_item(item: Node2D) -> bool:
    if has_item():
        # If the item isn't in the scene, we can free it
        if not item.is_inside_tree():
            item.queue_free()
        else:
            return false
    
    if item.is_inside_tree():
        # It's already in the tree, so we're probably picking it up
        SoundManager.item_taken(item)
    else:
        # Ensure the item is in the scene at all so we can reparent it
        get_tree().current_scene.add_child(item)

    held_item = item
    items_changed.emit(inventory_items, held_item_index)
    
    # Will reparent to wherever we need it
    item_scene_reparent.emit(item)

    held_item.position = Vector2.ZERO

    return true

## Removes the currently held item from the inventory and returns it.
## The item is not freed, and it's removed as a child of the player.
## Note that, unlike try_grab_item, this can't play suitable sounds since
## we don't know where the item is going.
func remove_item() -> Node2D:
    if not has_item():
        push_error("Tried to remove item when none was held!")
        return null
    
    var item = held_item
    
    held_item = null
    items_changed.emit(inventory_items, held_item_index)

    item.get_parent().remove_child(item)
    
    return item


# For debugging only!
func _unhandled_input(event):
    # Disable in builds in case I forget :)
    if OS.has_feature("release") or OS.has_feature("production"):
        return

    var DEBUG_ITEMS = {
        KEY_1: "plate",
        KEY_2: "cooked_rice",
        KEY_3: "sliced_salmon",
        KEY_4: [], # cycle; set below
        KEY_5: ""
    }

    # We just put all of the remaining items in the cycle
    var ITEM_CYCLE_ITEMS = DataLoader.items.values().map(func(item: ItemData):
        return item.id
    )
    for item in DEBUG_ITEMS.values():
        if item is String:
            ITEM_CYCLE_ITEMS.erase(item)
        elif item is Array:
            for subitem in item:
                ITEM_CYCLE_ITEMS.erase(subitem)
    
    DEBUG_ITEMS[KEY_4] = ITEM_CYCLE_ITEMS

    if event is InputEventKey and event.pressed and not event.echo:
        var item = null
        if event.keycode in DEBUG_ITEMS:
            var item_id = DEBUG_ITEMS[event.keycode]
            if item_id is String:
                if item_id == "":
                    if has_item():
                        remove_item().queue_free()
                    return
                
                var data = DataLoader.get_item(item_id)
                if data:
                    item = create_item(data)
            elif item_id is Array: # Cycle through the items
                if has_item():
                    var current_id = held_item.data.id
                    var current_index = item_id.find(current_id)
                    var next_index = (current_index + 1) % item_id.size()
                    var data = DataLoader.get_item(item_id[next_index])
                    item = create_item(data)
                else:
                    var data = DataLoader.get_item(item_id[0])
                    item = create_item(data)
        
        if item != null:
            if has_item():
                remove_item().queue_free()
            try_grab_item(item)
