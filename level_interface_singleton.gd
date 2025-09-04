extends Node

func get_interface() -> Node:
    return get_tree().get_first_node_in_group("level_interface")

## @param new_text The new text to display, or "" to keep the current text.
func set_interact_text_shown(txt_name: String, show: bool, new_text: String):
    var interface = get_interface()
    if interface:
        interface.set_interact_text_shown(txt_name, show, new_text)
