extends Resource

class_name OrderPossibilities

@export var single_items: Array[ItemData] = []
@export var color: Color = Color.WHITE
@export var name: String = "Unknown"

func get_random_item() -> ItemData:
    if single_items.size() == 0:
        return null
    var index = randi() % single_items.size()
    return single_items[index]
