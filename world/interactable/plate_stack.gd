extends "res://world/interactable/interactable.gd"

const plateData = preload("res://world/items/data/plate_item_data.tres");

@onready var takePlateAudio = $%TakePlateAudio

func can_add_to_plate(item: ItemData) -> bool:
    return item.id != "plate"

func take_plate():
    # Create a new plate scene
    var plate = PlayerInventorySingleton.create_item(plateData)
    PlayerInventorySingleton.try_grab_item(plate)
    
    takePlateAudio.pitch_scale = randf_range(0.9, 1.1)
    takePlateAudio.play()

func take_plate_add():
    var plate = PlayerInventorySingleton.create_item(plateData)
    var item = PlayerInventorySingleton.remove_item()
    plate.add_to_plate(item.data)
    item.queue_free()
    PlayerInventorySingleton.try_grab_item(plate)
    
    takePlateAudio.pitch_scale = randf_range(0.9, 1.1)
    takePlateAudio.play()

func get_interaction_data() -> InteractionData:
    var action = null
    if not PlayerInventorySingleton.has_item():
        action = InteractionAction.new("Take plate", take_plate)
    elif can_add_to_plate(PlayerInventorySingleton.held_item_data()):
        action = InteractionAction.new("Take plate and add %s" % PlayerInventorySingleton.held_item_data().item_name.to_lower(), take_plate_add, 0.25)
    
    return InteractionData.new(
        "Plate Stack",
        "A stack of clean plates. You can take one.",
        action
    )
