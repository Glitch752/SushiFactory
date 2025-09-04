extends "res://world/interactable/interactable.gd"


var cooking_time_remaining = 0.0
var has_rice = false


func interact():
    if !has_rice:
        var rice = PlayerInventorySingleton.remove_item()
        rice.queue_free()

        has_rice = true
        cooking_time_remaining = 5.0
        get_tree().create_timer(0.1).connect("timeout", _on_cooking_timer_timeout)
    elif cooking_time_remaining == 0:
        var rice = PlayerInventorySingleton.create_item(load("res://world/items/cooked_rice_item_data.tres"))
        PlayerInventorySingleton.try_grab_item(rice)
        has_rice = false

func _on_cooking_timer_timeout():
    if cooking_time_remaining > 0:
        cooking_time_remaining -= 0.1
        get_tree().create_timer(0.1).connect("timeout", _on_cooking_timer_timeout)
    else:
        cooking_time_remaining = 0

func can_interact() -> bool:
    if !has_rice:
        return PlayerInventorySingleton.holding_item("rice")
    elif cooking_time_remaining == 0:
        return !PlayerInventorySingleton.has_item()
    return false

func get_interact_explanation():
    if !has_rice:
        return "add rice to the rice cooker"
    elif cooking_time_remaining == 0:
        return "take cooked rice from the rice cooker"
    return ""
