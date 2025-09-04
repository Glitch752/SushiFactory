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
