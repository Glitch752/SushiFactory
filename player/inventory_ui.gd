extends Panel

func _ready():
    PlayerInventorySingleton.item_changed.connect(_item_changed)

func _item_changed(item: Node2D):
    if item:
        $TextureRect.visible = true
        $TextureRect.texture = item.data.item_sprite
        $ItemDescription/MarginContainer/RichTextLabel.text = item.get_description()
    else:
        $TextureRect.visible = false
        $ItemDescription.visible = false


func _on_mouse_entered():
    if PlayerInventorySingleton.has_item():
        $ItemDescription.visible = true

func _on_mouse_exited():
    $ItemDescription.visible = false
