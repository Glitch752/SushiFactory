extends Node

@export var held_item: Node2D = null

signal item_changed(item: Node2D)
## Should only be connected to by the object that wants to hold our current item, e.g. the player's carried item manager.
## This probably isn't the best way to structure this, but meh
signal item_scene_reparent(item: Node2D)

var ItemScene = preload("res://world/items/item.tscn")

func create_item(data: ItemData) -> Node2D:
    var item = ItemScene.instantiate()

    item.data = data
    item.apply_data()

    return item

func create_item_from_scene(scene: Resource) -> Node2D:
    var item = scene.instantiate()
    return item

func has_item() -> bool:
    return held_item != null

func holding_item(id: String) -> bool:
    return has_item() and held_item.data.id == id

func held_item_data() -> ItemData:
    if has_item():
        return held_item.data
    return null

func try_grab_item(item: Node2D) -> bool:
    if has_item():
        # If the item isn't in the scene, we can free it
        if not item.is_inside_tree():
            item.queue_free()
        else:
            return false
    
    if not item.is_inside_tree():
        get_tree().current_scene.add_child(item)

    held_item = item
    emit_signal("item_changed", held_item)
    
    # Will reparent to wherever we need it
    item_scene_reparent.emit(item)

    held_item.position = Vector2.ZERO

    return true

func remove_item() -> Node2D:
    var item = held_item
    
    held_item = null
    emit_signal("item_changed", null)

    item.get_parent().remove_child(item)
    
    return item

func load_item_data(item_id: String) -> ItemData:
    return load("res://world/items/data/%s_item_data.tres" % item_id)