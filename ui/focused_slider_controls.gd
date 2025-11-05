extends HSlider

func _on_gui_input(event: InputEvent) -> void:
    # TODO: This deserves some polish like autorepeat but is good enough for now
    if event.is_action_pressed("ui_left"):
        value -= max_value / 10
    elif event.is_action_pressed("ui_right"):
        value += max_value / 10
    value = clamp(value, 0, max_value)
