extends Panel

func _ready():
    PlayerInventorySingleton.item_changed.connect(_item_changed)

func _item_changed(item: ItemData):
    if item:
        $TextureRect.visible = true
        $TextureRect.texture = item.item_sprite
    else:
        $TextureRect.visible = false
