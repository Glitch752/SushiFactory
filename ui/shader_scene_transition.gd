extends CanvasLayer

@onready var mat: ShaderMaterial = $ColorRect.material

@onready var transitionInWoosh: AudioStreamPlayer = $TransitionInWoosh
@onready var transitionOutWoosh: AudioStreamPlayer = $TransitionOutWoosh

func wipe_to_black(duration := 1.25):
    mat.set_shader_parameter("direction", Vector2(1, 1))
    mat.set_shader_parameter("progress", 0.0)
    var t = get_tree().create_tween()
    t.tween_property(mat, "shader_parameter/progress", 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
    
    t.parallel().tween_callback(func():
        transitionInWoosh.play()
    ).set_delay(0.25)
    
    await t.finished

func wipe_from_black(duration := 1.25):
    mat.set_shader_parameter("direction", Vector2(-1, -1))
    mat.set_shader_parameter("progress", 1.0)
    var t = get_tree().create_tween()
    t.tween_property(mat, "shader_parameter/progress", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
    
    t.parallel().tween_callback(func():
        transitionOutWoosh.play()
    ).set_delay(0.25)
    
    await t.finished
