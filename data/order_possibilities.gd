extends Resource

class_name OrderPossibilities

@export var single_items: Array[ItemData] = []
@export var color: Color = Color.WHITE
@export var name: String = "Unknown":
    get:
        return tr(name)
## The amount paid when this dish is served to a customer.
## This is in Yen! 1 usd ~= 150 yen.
@export var pay: int = 0

func get_random_item() -> ItemData:
    if single_items.size() == 0:
        return null
    var index = randi() % single_items.size()
    return single_items[index]
