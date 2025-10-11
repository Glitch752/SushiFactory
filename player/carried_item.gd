extends Node2D

@onready var automation_objects = $"..".automation_objects_tilemap

func _ready():
    PlayerInventorySingleton.item_scene_reparent.connect(_item_scene_reparent)

func _item_scene_reparent(item: Node2D):
    item.reparent($".")
    item.position = Vector2.ZERO

func _process(_delta):
    var facing = $"..".facing
    position = facing * 8 + Vector2(0, -4)
    
    z_index = 0
    if facing != Vector2.UP:
        # If we're facing to the side or down and there is a table below us, "hold" the item above it instead of below
        if automation_objects.is_counter_at(global_position + facing * 4):
            z_index = 1
    
    show_behind_parent = facing == Vector2.UP
