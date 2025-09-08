extends "res://world/interactable/interactable.gd"

const CUT_ITEMS = {
    "cucumber": "sliced_cucumber",
    "salmon": "sliced_salmon"
}

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
            
            add_child(new_item)
            item = new_item

            cut_progress = 0
    elif cut_progress < CUTS_REQUIRED:
        cut_progress += 1

        if cut_progress == CUTS_REQUIRED:
            var sliced_item_id = CUT_ITEMS.get(item.data.id, null)

            remove_child(item)
            item.queue_free()
            
            var sliced_item = PlayerInventorySingleton.create_item(load("res://world/items/data/%s_item_data.tres" % sliced_item_id))
            add_child(sliced_item)
            
            item = sliced_item
    else:
        PlayerInventorySingleton.try_grab_item(item)
        item = null
            
        cut_progress = 0
    
    update_progressbar()

func update_progressbar():
    var progress_bar: AnimatedSprite2D = $ProgressBar
    progress_bar.visible = has_item() and cut_progress < CUTS_REQUIRED
    if has_item() and cut_progress < CUTS_REQUIRED:
        var frame_count = progress_bar.sprite_frames.get_frame_count("default");
        progress_bar.frame = int((cut_progress / CUTS_REQUIRED) * frame_count) % frame_count

func can_interact() -> bool:
    if !has_item():
        var held_item = PlayerInventorySingleton.held_item_data()
        return held_item and held_item.id in CUT_ITEMS.keys()
    
    return !PlayerInventorySingleton.has_item()

func get_interact_explanation():
    if !has_item():
        return "place " + PlayerInventorySingleton.held_item_data().item_name.to_lower() + " on the cutting board"
    elif cut_progress < CUTS_REQUIRED:
        return "cut the " + item.data.item_name.to_lower()
    else:
        return "take the " + item.data.item_name.to_lower()

func get_interactable_name():
    return "Cutting Board"

func get_description():
    if has_item():
        return "A cutting board with %s on it.\nYou have cut it %d out of %d times." % [item.data.item_name.to_lower(), cut_progress, CUTS_REQUIRED]
    else:
        return "A cutting board.\nYou can place certain items on it to cut them."
