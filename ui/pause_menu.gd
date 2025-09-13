extends Control

@onready var mat: ShaderMaterial = $ColorRect.material

var paused = false
var animating = false
var timeScaleTween: Tween = null

func _ready():
    visible = false
    modulate.a = 0.0
    
    $%ReturnButton.pressed.connect(unpause)

func pause(duration = 0.75):
    if animating:
        return
    
    paused = true
    animating = true
    
    if timeScaleTween:
        timeScaleTween.kill()
    timeScaleTween = create_tween()
    timeScaleTween.set_ignore_time_scale(true)
    timeScaleTween.tween_property(Engine, "time_scale", 0.0, duration)

    mat.set_shader_parameter("direction", Vector2(6, 1))
    mat.set_shader_parameter("progress", 0.0)

    visible = true

    var t = create_tween()
    t.set_ignore_time_scale(true)
    t.tween_property(mat, "shader_parameter/progress", 0.7, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
    t.parallel().tween_property(self, "modulate:a", 1.0, duration * 0.25).set_delay(duration * 0.2)
    
    await t.finished
    get_tree().paused = true

    animating = false

func unpause(duration = 0.75):
    if animating:
        return
    
    paused = false
    animating = true
    
    get_tree().paused = false

    if timeScaleTween:
        timeScaleTween.kill()
    timeScaleTween = create_tween()
    timeScaleTween.set_ignore_time_scale(true)
    timeScaleTween.tween_property(Engine, "time_scale", 1.0, 0.1)

    var t = create_tween()
    t.set_ignore_time_scale(true)
    t.tween_property(mat, "shader_parameter/progress", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
    t.parallel().tween_property(self, "modulate:a", 0.0, duration * 0.25).set_delay(duration * 0.5)

    await t.finished

    animating = false
    visible = false

func _unhandled_key_input(event):
    if event.is_action_pressed("ui_cancel") and not event.is_echo():
        if not paused:
            pause()
        else:
            unpause()
        get_viewport().set_input_as_handled()
