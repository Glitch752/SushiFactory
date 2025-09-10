extends Node

signal money_changed(new_money: int)

signal interact_text_changed(txt_name: String, show: bool, new_text: String)
signal info_description_changed(new_text: Variant)

var _current_money: int = 0
@export var current_money: int:
    get:
        return _current_money
    set(value):
        _current_money = value
        money_changed.emit(_current_money)

## @param new_text The new text to display, or "" to keep the current text.
func set_interact_text_shown(txt_name: String, show: bool, new_text: String):
    interact_text_changed.emit(txt_name, show, new_text)

## @param new_text The new text to display, or null to hide the description.
func set_info_description(new_text: Variant):
    info_description_changed.emit(new_text)

func update_interactable(node: Node2D):
    set_interact_text_shown("Interact", true, "Press E to " + node.get_interact_explanation())
    set_info_description("[b]" + node.get_interactable_name() + "[/b]\n" + node.get_description())

func clear_interactable():
    set_interact_text_shown("Interact", false, "")
    set_info_description(null)
