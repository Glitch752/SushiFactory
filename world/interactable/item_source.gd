extends "res://world/interactable/interactable.gd"

@export var texture: Texture2D;
@export var item_data: ItemData;

func _ready():
    $Sprite2D.texture = texture
    super._ready()

func interact():
    var item = PlayerInventorySingleton.create_item(item_data)
    PlayerInventorySingleton.try_grab_item(item)

func can_interact() -> bool:
    return !PlayerInventorySingleton.has_item()

func get_interact_explanation():
    return "pick up a " + item_data.item_name.to_lower()

func get_interactable_name():
    return item_data.item_name + " Source"

func get_description():
    return "A source of " + item_data.item_name.to_lower() + ". You can pick one up here."
