extends "res://world/items/item.gd"

var contents: Array[ItemData] = []

func can_add(item: ItemData) -> bool:
    return item.id != "plate"

var rng = RandomNumberGenerator.new()

func add_to_plate(item: ItemData) -> void:
    print("Adding item to plate ", item.id)

    contents.append(item)

    var item_sprite = Sprite2D.new()
    item_sprite.texture = item.item_sprite
    item_sprite.scale = Vector2.ONE * 0.5
    item_sprite.position = Vector2(rng.randi_range(-4, 4), rng.randi_range(-4, 4))
    
    add_child(item_sprite)

func get_description():
    if contents.size() == 0:
        return "An empty plate."
    var desc = "A plate with:[ul]"
    for item in contents:
        desc += "\n %s" % item.item_name
    desc += "\n[/ul]"
    return desc
