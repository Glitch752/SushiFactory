extends "res://world/interactable/interactable.gd"

var PlateScene = preload("res://world/items/Plate.tscn");

func interact():
    # Create a new plate scene
    var plate = PlayerInventorySingleton.create_item_from_scene(PlateScene)
    PlayerInventorySingleton.try_grab_item(plate)

func can_interact() -> bool:
    return !PlayerInventorySingleton.has_item()

func get_interact_explanation():
    return "pick up a plate"