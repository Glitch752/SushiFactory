extends Area2D

var current_interactable: Variant = null

func _physics_process(_delta):
    var player = $".."
    position = player.facing * 12

func _unhandled_input(event):
    if event.is_action_pressed("interact") and current_interactable != null:
        if current_interactable.can_interact():
            current_interactable.interact()
            # Update the interaction state after each interaction
            if !current_interactable.can_interact():
                stop_interacting()
            else:
                LevelInterfaceSingleton.set_interact_text_shown("Interact", true, "Press E to " + current_interactable.get_interact_explanation())
                

func _on_area_entered(area: Area2D):
    if area.is_in_group("interact_zone"):
        if current_interactable != null:
            current_interactable.interact_hide()
        
        current_interactable = area.get_parent()
        if current_interactable.can_interact():
            current_interactable.interact_show()
            LevelInterfaceSingleton.set_interact_text_shown("Interact", true, "Press E to " + current_interactable.get_interact_explanation())

func _on_area_exited(area: Area2D):
    if area.is_in_group("interact_zone"):
        if area.get_parent() == current_interactable:
            stop_interacting()

func stop_interacting():
    current_interactable.interact_hide()
    current_interactable = null
    LevelInterfaceSingleton.set_interact_text_shown("Interact", false, "")
