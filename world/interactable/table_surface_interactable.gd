extends "res://world/interactable/interactable.gd"

var current_plate: Node2D = null

func interact():
    if !PlayerInventorySingleton.has_item() and current_plate != null:
        # Take the plate
        var plate = current_plate
        current_plate = null
        
        remove_child(plate)
        PlayerInventorySingleton.try_grab_item(plate)
        return
    
    if PlayerInventorySingleton.holding_item("plate") and current_plate == null:
        current_plate = PlayerInventorySingleton.remove_item()
        add_child(current_plate)
        return
    
    if PlayerInventorySingleton.held_item and current_plate.can_add(PlayerInventorySingleton.held_item_data()):
        var current_item = PlayerInventorySingleton.remove_item()
        current_plate.add_to_plate(current_item.data)
        current_item.queue_free()
        return

func can_interact() -> bool:
    if !PlayerInventorySingleton.has_item() and current_plate != null:
        return true
    
    if PlayerInventorySingleton.holding_item("plate") and current_plate == null:
        return true
    
    if PlayerInventorySingleton.held_item and current_plate and current_plate.can_add(PlayerInventorySingleton.held_item_data()):
        return true
    
    return false
