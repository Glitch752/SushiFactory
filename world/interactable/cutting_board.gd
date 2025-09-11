extends "res://world/interactable/interactable.gd"

var CUT_ITEMS = DishCombinationsSingleton.get_single_input_dishes_for("cutting_board")

var cut_progress = 0
var item = null

func has_item() -> bool:
    return item != null

const CUTS_REQUIRED = 6.0

func interact():
    if !has_item():
        var held_item = PlayerInventorySingleton.held_item_data()
        if held_item and held_item.id in CUT_ITEMS.keys():
            var new_item = PlayerInventorySingleton.remove_item()
            
            $InteractableContent.add_child(new_item)
            item = new_item

            cut_progress = 0
    elif cut_progress < CUTS_REQUIRED:
        cut_progress += 1

        if cut_progress == CUTS_REQUIRED:
            var sliced_item_id = CUT_ITEMS.get(item.data.id, null)

            $InteractableContent.remove_child(item)
            item.queue_free()
            
            var sliced_item = PlayerInventorySingleton.create_item(PlayerInventorySingleton.load_item_data(sliced_item_id))
            $InteractableContent.add_child(sliced_item)
            
            item = sliced_item
    else:
        PlayerInventorySingleton.try_grab_item(item)
        item = null
            
        cut_progress = 0
    
    update_progressbar()

func update_progressbar():
    var progress_bar: AnimatedSprite2D = $%ProgressBar
    progress_bar.visible = has_item() and cut_progress < CUTS_REQUIRED
    if has_item() and cut_progress < CUTS_REQUIRED:
        var frame_count = progress_bar.sprite_frames.get_frame_count("default");
        progress_bar.frame = int((cut_progress / CUTS_REQUIRED) * frame_count) % frame_count


func get_interaction_data() -> InteractionData:
    var action: InteractionAction = null
    var interactable_name = "Cutting Board"
    var desc = ""
    if !has_item():
        var held_item = PlayerInventorySingleton.held_item_data()
        if held_item and held_item.id in CUT_ITEMS.keys():
            action = InteractionAction.new("Place %s" % held_item.item_name, interact)
            desc = "A cutting board.\nPlace %s on it to cut." % held_item.item_name.to_lower()
        else:
            desc = "A cutting board.\nYou can place certain items on it to cut them."
    elif cut_progress < CUTS_REQUIRED:
        action = InteractionAction.new("Cut %s" % item.data.item_name, interact)
        desc = "A cutting board with %s on it.\nYou have cut it %d out of %d times." % [item.data.item_name.to_lower(), cut_progress, CUTS_REQUIRED]
    else:
        action = InteractionAction.new("Take %s" % item.data.item_name, interact)
        desc = "A cutting board with %s on it.\nCutting complete." % item.data.item_name.to_lower()
    return InteractionData.new(interactable_name, desc, action)
