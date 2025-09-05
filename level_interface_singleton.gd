extends Node

func get_interface() -> Node:
    return get_tree().get_first_node_in_group("level_interface")

## @param new_text The new text to display, or "" to keep the current text.
func set_interact_text_shown(txt_name: String, show: bool, new_text: String):
    var interface = get_interface()
    if interface:
        interface.set_interact_text_shown(txt_name, show, new_text)

## @param new_text The new text to display, or null to hide the description.
func set_info_description(new_text: Variant):
    var interface = get_interface()
    if interface:
        interface.set_info_description(new_text)

func update_interactable(node: Node2D):
    set_interact_text_shown("Interact", true, "Press E to " + node.get_interact_explanation())
    set_info_description("[b]" + node.get_interactable_name() + "[/b]\n" + node.get_description())

func clear_interactable():
    set_interact_text_shown("Interact", false, "")
    set_info_description(null)
