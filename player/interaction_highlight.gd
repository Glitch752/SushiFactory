@tool

extends Node2D

@export var color: Color = Color("#f7f3a1"):
    set(value):
        color = value
        _update_color()

@export var size: Vector2i = Vector2i(16, 16):
    set(value):
        size = value
        _update_size()

func _update_color():
    for child in get_children():
        (child as Polygon2D).color = color

func _update_size():
    # The 4 corners go at (size/2, size/2), (size/2, -size/2), etc.
    var s = Vector2(size)/2
    var positions = [s*Vector2(1, -1), s*Vector2(1, 1), s*Vector2(-1, 1), s*Vector2(-1, -1)]
    for idx in range(positions.size()):
        get_child(idx).position = positions[idx]
