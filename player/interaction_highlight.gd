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
    for idx in range(4):
        var child = get_child(idx)
        (child as Polygon2D).color = color

func _update_size():
    # The 4 corners go at (size/2, size/2), (size/2, -size/2), etc.
    var s = Vector2(size)/2
    var positions = [s*Vector2(1, -1), s*Vector2(1, 1), s*Vector2(-1, 1), s*Vector2(-1, -1)]
    for idx in range(positions.size()):
        get_child(idx).position = positions[idx]

var interp_tween = null
var color_target: Color

## global_target: Vector2 | null
## to_color: Color | null
func interp_to(global_target: Variant, to_color: Variant = null, duration = 0.04):
    if not global_target:
        visible = false
        return
    
    if visible:
        if interp_tween != null:
            interp_tween.kill()
            interp_tween = null
        
        interp_tween = create_tween()
        interp_tween.set_ignore_time_scale(true)
        interp_tween.tween_property(self, "global_position", global_target, duration)
        color_target = to_color if to_color else color_target
        interp_tween.parallel().tween_property(self, "color", color_target, duration)
    else:
        global_position = global_target
        color = to_color if to_color else color_target
    
    visible = true
