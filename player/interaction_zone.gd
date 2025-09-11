extends Area2D

## Vector2i if interacting with the automation map, Node2D if interacting with an Interactable
var current_interactable: Variant = null

var automation_manager

func _ready():
    automation_manager = get_node("../../%AutomationManager")
    if automation_manager == null:
        push_error("Could not find AutomationManager node.")

func _physics_process(_delta):
    var player = $".."
    position = player.facing * 12

    var automation_interact_pos: Vector2i = automation_manager.get_interaction_position(global_position)
    if automation_manager.can_interact(automation_interact_pos):
        if not (current_interactable is Vector2i):
            current_interactable = automation_interact_pos
        LevelInterfaceSingleton.update_interactable(automation_manager)
    elif current_interactable is Vector2i:
        stop_interacting()

func _unhandled_input(event):
    if event.is_action_pressed("interact") and current_interactable != null:
        if current_interactable is Vector2i:
            automation_manager.interact(current_interactable)
            # Update the interaction state after each interaction
            if not automation_manager.can_interact(current_interactable):
                stop_interacting()
            else:
                LevelInterfaceSingleton.update_interactable(automation_manager)
        elif current_interactable is Node2D and current_interactable.has_method("interact") and current_interactable.has_method("can_interact"):
            current_interactable.interact()
            # Update the interaction state after each interaction
            if !current_interactable.can_interact():
                stop_interacting()
            else:
                LevelInterfaceSingleton.update_interactable(current_interactable)
        else:
            push_error("Unsupported interactable interface")

func _on_area_entered(area: Area2D):
    if area.is_in_group("interact_zone"):
        if current_interactable is Node2D:
            current_interactable.interact_hide()
        
        current_interactable = area.get_parent().get_parent()
        if current_interactable.can_interact():
            current_interactable.interact_show()
            LevelInterfaceSingleton.update_interactable(current_interactable)

func _on_area_exited(area: Area2D):
    if area.is_in_group("interact_zone") and not (current_interactable is Vector2i):
        if area.get_parent().get_parent() == current_interactable:
            stop_interacting()

func stop_interacting():
    if current_interactable is Node2D:
        current_interactable.interact_hide()
    current_interactable = null
    LevelInterfaceSingleton.clear_interactable()
