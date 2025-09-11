extends Node2D

func _ready():
    PlayerInventorySingleton.item_scene_reparent.connect(_item_scene_reparent)

func _item_scene_reparent(item: Node2D):
    item.reparent($".")

func _process(_delta):
    var facing = $"..".facing
    position = facing * 8 + Vector2(0, -4)
    z_index = -10 if facing == Vector2.UP else 1
