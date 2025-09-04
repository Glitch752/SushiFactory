extends "res://world/items/item.gd"

func can_add(item: ItemData) -> bool:
    return true

func add_to_plate(item: ItemData) -> void:
    print("Adding item to plate ", item.id)
    pass
