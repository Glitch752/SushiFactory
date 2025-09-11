extends "res://world/interactable/interactable.gd"


func interact():
    var item = PlayerInventorySingleton.remove_item()
    if item:
        item.queue_free()

func get_interaction_data() -> InteractionData:
    var action: InteractionAction = null
    var interactable_name = "Trash Can"
    var desc = "A trash can. You can throw away items here."
    if PlayerInventorySingleton.has_item():
        var held_item = PlayerInventorySingleton.held_item_data()
        action = InteractionAction.new("Throw Away %s" % held_item.item_name, interact)
        desc = "A trash can. Throw away the %s here." % held_item.item_name.to_lower()
    return InteractionData.new(interactable_name, desc, action)
