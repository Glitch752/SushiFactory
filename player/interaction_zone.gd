extends Area2D

var current_interactable: Variant = null

func _unhandled_input(event):
    if event.is_action_pressed("interact") and current_interactable != null:
        current_interactable.interact()

func _on_area_entered(area: Area2D):
    if area.is_in_group("interact_zone"):
        if current_interactable != null:
            current_interactable.interact_hide()
        
        current_interactable = area.get_parent()
        current_interactable.interact_show()

func _on_area_exited(area: Area2D):
    if area.is_in_group("interact_zone"):
        if area.get_parent() == current_interactable:
            current_interactable.interact_hide()
            current_interactable = null
