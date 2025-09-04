extends "res://world/interactable/interactable.gd"

func interact():
    var item = PlayerInventorySingleton.remove_item()
    if item:
        item.queue_free()

func can_interact() -> bool:
    return PlayerInventorySingleton.has_item()
