extends "res://world/interactable/interactable.gd"

var current_object: Node2D = null

func has_plate():
    return current_object != null and current_object.data.id == "plate"

func interact():
    if !PlayerInventorySingleton.has_item() and current_object != null:
        var object = current_object
        current_object = null
        
        remove_child(object)
        PlayerInventorySingleton.try_grab_item(object)
        return
    
    if PlayerInventorySingleton.has_item() and current_object == null:
        current_object = PlayerInventorySingleton.remove_item()
        add_child(current_object)
        return
    
    if has_plate() and PlayerInventorySingleton.held_item and current_object.can_add(PlayerInventorySingleton.held_item_data()):
        var current_item = PlayerInventorySingleton.remove_item()
        current_object.add_to_plate(current_item.data)
        current_item.queue_free()
        return

func can_interact() -> bool:
    if !PlayerInventorySingleton.has_item() and current_object != null:
        return true
    
    if PlayerInventorySingleton.has_item() and current_object == null:
        return true
    
    if has_plate() and PlayerInventorySingleton.held_item and current_object.can_add(PlayerInventorySingleton.held_item_data()):
        return true
    
    return false

func get_interact_explanation():
    if !PlayerInventorySingleton.has_item() and current_object != null:
        return "take the " + current_object.data.item_name.to_lower()
    
    if PlayerInventorySingleton.has_item() and current_object == null:
        return "place the " + PlayerInventorySingleton.held_item_data().item_name.to_lower() + " on the table"
    
    if PlayerInventorySingleton.held_item and current_object and current_object.can_add(PlayerInventorySingleton.held_item_data()):
        return "put the " + PlayerInventorySingleton.held_item_data().item_name.to_lower() + " on the plate"
    
    return ""

func get_interactable_name():
    return "Table"

func get_description():
    if current_object == null:
        return "An empty table."
    return "A table with:[ul]\n " + current_object.get_description() + "\n[/ul]"
