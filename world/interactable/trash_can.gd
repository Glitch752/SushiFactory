extends "res://world/interactable/interactable.gd"

func interact():
    var item = PlayerInventorySingleton.remove_item()
    if item:
        item.queue_free()

func can_interact() -> bool:
    return PlayerInventorySingleton.has_item()

func get_interact_explanation():
    return "throw away the " + PlayerInventorySingleton.held_item_data().item_name.to_lower()
