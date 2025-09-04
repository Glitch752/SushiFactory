extends "res://world/interactable/interactable.gd"

func interact():
    # Create a new plate scene
    var plate = PlayerInventorySingleton.create_item(load("res://world/items/plate_item_data.tres"))
    PlayerInventorySingleton.try_grab_item(plate)
