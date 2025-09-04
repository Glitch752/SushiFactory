extends Node

@export var held_item: Node2D = null

var ItemScene = preload("res://world/items/item.tscn")

func create_item(data: ItemData) -> Node2D:
    var item = ItemScene.instantiate()
    get_tree().current_scene.add_child(item)

    item.data = data
    item.apply_data()

    return item

func has_item() -> bool:
    return held_item != null

func try_grab_item(item: Node2D) -> bool:
    if has_item():
        return false
    
    held_item = item

    held_item.position = Vector2.ZERO

    return true

func _process(_delta):
    print(has_item())
