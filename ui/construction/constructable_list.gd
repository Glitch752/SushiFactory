extends HBoxContainer

const CONSTRUCTABLE_ITEM = preload("res://ui/construction/ConstructableItem.tscn")

@export var selected: int = 0:
    set(val):
        selected = val
        _update_selected()

func _update_selected():
    for i in get_child_count():
        get_child(i).selected = i == selected

func _ready():
    for child in get_children(): # Editor placeholders
        child.queue_free()
    
    for i in DataLoader.constructables.size():
        var constructable = DataLoader.constructables[i]
        
        var node = CONSTRUCTABLE_ITEM.instantiate()
        node.texture = constructable.texture
        node.selected = i == selected
        
        add_child(node)
