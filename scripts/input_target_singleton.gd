extends Node

enum InputTarget {
    # Ordered by increasing priority
    PlayerMovement,
    ComputerDesktop,
    ConstructionMenu,
    PauseMenu
}

var target_time_scales: Dictionary[InputTarget, float] = {
    InputTarget.PlayerMovement: 1.0,
    InputTarget.ComputerDesktop: 0.05,
    InputTarget.ConstructionMenu: 0.05,
    InputTarget.PauseMenu: 0.0
}

var active: Dictionary[InputTarget, bool] = {}

var timeScaleTween = null

func _ready():
    for target in InputTarget.values():
        active[target] = false
    active[InputTarget.PlayerMovement] = true

func get_active_input_target() -> InputTarget:
    var max_active = 0
    for target in active.keys():
        if active[target] and target > max_active:
            max_active = target
    return max_active as InputTarget

func is_active(target: InputTarget):
    return get_active_input_target() == target
    
func is_any_active(targets: Array[InputTarget]):
    return get_active_input_target() in targets

func activate(target: InputTarget):
    call_deferred("_activate", target)

func _activate(target: InputTarget):
    var last_target = get_active_input_target()
    active[target] = true
    var current_target = get_active_input_target()
    if current_target != last_target:
        _update_time_scale(current_target)

func deactivate(target: InputTarget):
    call_deferred("_deactivate", target)

func _deactivate(target: InputTarget):
    var last_target = get_active_input_target()
    active[target] = false
    var current_target = get_active_input_target()
    if current_target != last_target:
        _update_time_scale(current_target)

func _update_time_scale(target: InputTarget):
    # From the Godot documentation:
    # `Note: It's recommended to keep this property above 0.0, as the game may behave unexpectedly otherwise.`
    # I originally set this to 0, but it does in fact create some weird issues.
    # Therefore, we run the game at 5% speed when in the computer to give players a bit of a pause.

    var decreasing = target_time_scales[target] < Engine.time_scale

    if timeScaleTween:
        timeScaleTween.kill()
    timeScaleTween = create_tween()
    timeScaleTween.set_ignore_time_scale(true)
    timeScaleTween.tween_property(Engine, "time_scale", target_time_scales[target], 0.5 if decreasing else 0.05)
