extends Node

@export var held_item: Node2D = null

signal item_changed(item: Node2D)
## Should only be connected to by the object that wants to hold our current item, e.g. the player's carried item manager.
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
    item_changed.emit(held_item)
    
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
    item_changed.emit(null)

    item.get_parent().remove_child(item)
    
    return item

func load_item_data(item_id: StringName) -> ItemData:
    if item_id == null:
        push_error("Tried to load a null item!")
        return preload("res://world/items/data/cucumber_item_data.tres")
    return load("res://world/items/data/%s_item_data.tres" % item_id)


# For debugging only!
func _unhandled_input(event):
    # Disable in builds in case I forget :)
    if OS.has_feature("release") or OS.has_feature("production"):
        return

    var DEBUG_ITEMS = {
        KEY_1: "plate",
        KEY_2: "cooked_rice",
        KEY_3: "sliced_salmon",
        KEY_4: ""
    }

    if event is InputEventKey and event.pressed and not event.echo:
        var item = null
        if event.keycode in DEBUG_ITEMS:
            var item_id = DEBUG_ITEMS[event.keycode]
            if item_id is String:
                if item_id == "":
                    if has_item():
                        remove_item().queue_free()
                    return
                
                var data = load_item_data(item_id)
                item = create_item(data)
            elif item_id is Node2D:
                item = item_id.duplicate()
        
        if item != null:
            if has_item():
                remove_item().queue_free()
            try_grab_item(item)
