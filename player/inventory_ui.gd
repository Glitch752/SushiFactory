extends Panel

func _ready():
    PlayerInventorySingleton.item_changed.connect(_item_changed)
    
    $ItemDescription.visible = false
    $ItemDescription.modulate.a = 0
    $ItemDescription.visual_position = Vector2(0, -5)

func _item_changed(item: Node2D):
    if item:
        $TextureRect.visible = true
        $TextureRect.texture = item.data.item_sprite
        $%ItemDescriptionLabel.text = item.get_description()
    else:
        $TextureRect.visible = false
        $ItemDescription.visible = false


func _on_mouse_entered():
    if PlayerInventorySingleton.has_item():
        $ItemDescription.visible = true
        var t = create_tween()
        t.set_ignore_time_scale(true)
        t.tween_property($ItemDescription, "modulate:a", 1, 0.1)
        t.parallel().tween_property($ItemDescription, "visual_position:y", 0, 0.1)

func _on_mouse_exited():
    var t = create_tween()
    t.set_ignore_time_scale(true)
    t.tween_property($ItemDescription, "modulate:a", 0, 0.1)
    t.parallel().tween_property($ItemDescription, "visual_position:y", -5, 0.1)
    t.tween_callback(func():
        $ItemDescription.visible = false
    )
