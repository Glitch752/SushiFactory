extends "res://world/interactable/interactable.gd"

var PlateScene = preload("res://world/items/Plate.tscn");

func interact():
    # Create a new plate scene
    var plate = PlayerInventorySingleton.create_item_from_scene(PlateScene)
    PlayerInventorySingleton.try_grab_item(plate)

func get_interaction_data() -> InteractionData:
    return InteractionData.new(
        "Plate Stack",
        "A stack of clean plates. You can take one.",
        InteractionAction.new("Take Plate", interact) if not PlayerInventorySingleton.has_item() else null
    )
