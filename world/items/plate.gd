extends "res://world/items/item.gd"

func can_add(item: ItemData) -> bool:
    return item.id != "plate"

var rng = RandomNumberGenerator.new()

func add_to_plate(item: ItemData) -> void:
    print("Adding item to plate ", item.id)

    var item_sprite = Sprite2D.new()
    item_sprite.texture = item.item_sprite
    item_sprite.scale = Vector2.ONE * 0.5
    item_sprite.position = Vector2(rng.randi_range(-4, 4), rng.randi_range(-4, 4))
    
    add_child(item_sprite)

    pass
