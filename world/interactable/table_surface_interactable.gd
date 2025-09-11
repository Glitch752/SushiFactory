extends "res://world/interactable/interactable.gd"

var current_object: Node2D = null

func has_plate():
    return current_object != null and current_object.data.id == "plate"

func interact():
    if !PlayerInventorySingleton.has_item() and current_object != null:
        var object = current_object
        current_object = null
        
        $InteractableContent.remove_child(object)
        PlayerInventorySingleton.try_grab_item(object)
        return
    
    if PlayerInventorySingleton.has_item() and current_object == null:
        current_object = PlayerInventorySingleton.remove_item()
        $InteractableContent.add_child(current_object)
        return
    
    if has_plate() and PlayerInventorySingleton.held_item and current_object.can_add(PlayerInventorySingleton.held_item_data()):
        var current_item = PlayerInventorySingleton.remove_item()
        current_object.add_to_plate(current_item.data)
        current_item.queue_free()
        return

func lower_start(text: String) -> String:
    if text.is_empty():
        return text
    return text[0].to_lower() + text.substr(1, text.length() - 1)

func get_interaction_data() -> InteractionData:
    var action: InteractionAction = null
    var interactable_name = "Table"
    if !PlayerInventorySingleton.has_item() and current_object != null:
        action = InteractionAction.new("Take %s" % current_object.data.item_name, interact)
    elif PlayerInventorySingleton.has_item() and current_object == null:
        var held_item = PlayerInventorySingleton.held_item_data()
        action = InteractionAction.new("Place %s" % held_item.item_name, interact)
    elif has_plate() and PlayerInventorySingleton.held_item and current_object.can_add(PlayerInventorySingleton.held_item_data()):
        var held_item = PlayerInventorySingleton.held_item_data()
        action = InteractionAction.new("Put %s on the plate" % held_item.item_name, interact)
    
    var desc = "An empty table." if current_object == null else "Has %s" % lower_start(current_object.get_description())
    return InteractionData.new(interactable_name, desc, action)
