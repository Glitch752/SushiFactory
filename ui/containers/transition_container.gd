@tool

extends TransformContainer

class_name TransitionContainer

var min_height_scalar: float = 0.0:
    set(value):
        min_height_scalar = value
        update_minimum_size()

func _ready():
    if Engine.is_editor_hint():
        return
    visual_position = Vector2(20, 0)
    modulate.a = 0

    var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
    t.set_ignore_time_scale(true)

    t.tween_property(self, "visual_position", Vector2.ZERO, 0.3)
    t.parallel().tween_property(self, "modulate:a", 1, 0.3)
    t.parallel().tween_property(self, "min_height_scalar", 1.0, 0.2)

func remove():
    var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
    t.set_ignore_time_scale(true)
    
    t.tween_property(self, "visual_position", Vector2(0, -20), 0.3)
    t.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
    t.parallel().tween_property(self, "min_height_scalar", 0.0, 0.2)

    t.finished.connect(queue_free)

func _get_minimum_size() -> Vector2:
    var min_size = super._get_minimum_size()
    return Vector2(min_size.x, min_size.y * min_height_scalar)
