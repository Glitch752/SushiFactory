extends VBoxContainer

const CONSTRUCTABLE_ITEM = preload("res://ui/construction/ConstructableItem.tscn")

@onready var item_list: HBoxContainer = $%ItemList

@export var selected: int = 0:
    set(val):
        selected = val
        _update_selected()

func _update_selected():
    for i in item_list.get_child_count():
        item_list.get_child(i).selected = i == selected
    
    var selectedConstructable = DataLoader.constructables[selected]
    $%ConstructableDescription.description = "[b]%s[/b]\n%s" % [selectedConstructable.name, selectedConstructable.description]

func _ready():
    for child in item_list.get_children(): # Editor placeholders
        child.queue_free()
    
    for i in DataLoader.constructables.size():
        var constructable = DataLoader.constructables[i]
        
        var node = CONSTRUCTABLE_ITEM.instantiate()
        node.texture = constructable.texture
        node.selected = i == selected
        
        item_list.add_child(node)
