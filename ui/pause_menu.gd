extends Control

const ShaderSceneTransition = preload("res://ui/ShaderSceneTransition.tscn")

@onready var mat: ShaderMaterial = $ColorRect.material

@onready var transitionInWoosh: AudioStreamPlayer = $TransitionInWoosh
@onready var transitionOutWoosh: AudioStreamPlayer = $TransitionOutWoosh

var paused = false
var animating = false
var audioTween: Tween = null

func _ready():
    visible = false
    modulate.a = 0.0
    
    $%ReturnButton.pressed.connect(unpause)
    $%ExitButton.pressed.connect(exit_to_menu)

    DayManagerSingleton.day_started.connect(func(_day, _day_data, info_text): day_started(info_text))
    LocalizationSingleton.changed.connect(func(): day_started(DayManagerSingleton.generate_day_opening_info()))

func day_started(info_text: String):
    $%CurrentDayStats.text = info_text

func pause(duration = 0.75):
    if animating:
        return
    
    $%ReturnButton.grab_focus.call_deferred()
    
    paused = true
    animating = true
    InputTargetSingleton.activate(InputTargetSingleton.InputTarget.PauseMenu)
    
    var lowPass: AudioEffectLowPassFilter = AudioServer.get_bus_effect(AudioServer.get_bus_index("Music"), 0)

    if audioTween:
        audioTween.kill()
    audioTween = create_tween()
    audioTween.set_ignore_time_scale(true)
    audioTween.parallel().tween_property(lowPass, "cutoff_hz", 1800, duration)

    mat.set_shader_parameter("direction", Vector2(6, 1))
    mat.set_shader_parameter("progress", 0.0)

    visible = true

    var t = create_tween()
    t.set_ignore_time_scale(true)
    t.tween_property(mat, "shader_parameter/progress", 0.7, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
    t.parallel().tween_property(self, "modulate:a", 1.0, duration * 0.25).set_delay(duration * 0.2)
    
    t.parallel().tween_callback(func():
        transitionInWoosh.play()
    ).set_delay(0.25)
    
    await t.finished
    get_tree().paused = true

    animating = false

func exit_to_menu():
    unpause()
    
    var transition = ShaderSceneTransition.instantiate()
    get_tree().root.add_child(transition)
    await transition.wipe_to_black()

    # Not sure why this can't be preloaded, but whatever
    get_tree().change_scene_to_packed(load("res://Menu.tscn"))

    await transition.wipe_from_black()
    transition.queue_free()
    

func unpause(duration = 0.75):
    if animating:
        return
    
    get_tree().paused = false
    
    paused = false
    animating = true
    InputTargetSingleton.deactivate(InputTargetSingleton.InputTarget.PauseMenu)

    var lowPass: AudioEffectLowPassFilter = AudioServer.get_bus_effect(AudioServer.get_bus_index("Music"), 0)
    
    if audioTween:
        audioTween.kill()
    audioTween = create_tween()
    audioTween.set_ignore_time_scale(true)
    audioTween.parallel().tween_property(lowPass, "cutoff_hz", 22000, duration)

    var t = create_tween()
    t.set_ignore_time_scale(true)
    t.tween_property(mat, "shader_parameter/progress", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
    t.parallel().tween_property(self, "modulate:a", 0.0, duration * 0.25).set_delay(duration * 0.5)

    t.parallel().tween_callback(func():
        transitionOutWoosh.play()
    ).set_delay(0.25)
    
    await t.finished

    animating = false
    visible = false

func _unhandled_key_input(event):
    if not InputTargetSingleton.is_any_active([InputTargetSingleton.InputTarget.PlayerMovement, InputTargetSingleton.InputTarget.PauseMenu]):
        return
    
    if event.is_action_pressed("pause") and not event.is_echo():
        if not paused:
            pause()
        else:
            unpause()
        get_viewport().set_input_as_handled()
