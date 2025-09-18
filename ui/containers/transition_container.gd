@tool

extends TransformContainer

class_name TransitionContainer

func _ready():
    if Engine.is_editor_hint():
        return
    visual_position = Vector2(20, 0)
    modulate.a = 0

    var t = create_tween()
    t.set_ignore_time_scale(true)

    t.tween_property(self, "visual_position", Vector2.ZERO, 0.25)
    t.parallel().tween_property(self, "modulate:a", 1, 0.25)
    t.parallel().tween_property(self, "scale:y", 1, 0.25).from(0)

func remove():
    var t = create_tween()
    t.set_ignore_time_scale(true)
    
    t.tween_property(self, "visual_position", Vector2(20, 0), 0.25)
    t.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
    t.parallel().tween_property(self, "scale:y", 0.0, 0.25)

    t.finished.connect(queue_free)
