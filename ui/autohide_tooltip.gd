@tool

extends TransformContainer

@export var transition_dir: Vector2

var hide_timer: Timer = null

@export_multiline var description: String:
    set(val):
        if description == val:
            return
        
        description = val
        
        if not description.is_empty():
            $%ItemDescriptionLabel.text = val

            # Show briefly
            _show()
            
            if hide_timer:
                hide_timer.stop()
                hide_timer.queue_free()
            
            hide_timer = Timer.new()
            hide_timer.one_shot = true
            hide_timer.wait_time = 2.0
            hide_timer.autostart = true
            hide_timer.ignore_time_scale = true
            hide_timer.timeout.connect(_hide)
            add_child(hide_timer)
        else:
            if hide_timer:
                hide_timer.stop()
                hide_timer.queue_free()
                hide_timer = null
            _hide()

func _show():
    var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_ignore_time_scale(true)
    
    t.tween_property(self, "visual_position", Vector2.ZERO, 0.3)
    t.parallel().tween_property(self, "modulate:a", 1, 0.3)

func _hide():
    var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_ignore_time_scale(true)
    
    t.tween_property(self, "visual_position", transition_dir, 0.3)
    t.parallel().tween_property(self, "modulate:a", 0, 0.3)

func _ready():
    if not Engine.is_editor_hint():
        modulate.a = 0
        visual_position = transition_dir
