extends Node

signal money_changed(new_money: int)
signal day_changed(new_day: int)
signal time_of_day_changed(new_time_of_day: float)

signal interact_text_changed(txt_name: String, show: bool, new_text: String)
signal info_description_changed(new_text: Variant)

var _current_money: int = 0
@export var current_money: int:
    get:
        return _current_money
    set(value):
        _current_money = value
        money_changed.emit(_current_money)

var _day: int = 0
@export var day: int:
    get:
        return _day
    set(value):
        _day = value
        day_changed.emit(_day)

## Time of day, in hours. 0.0 to 24.0
var _time_of_day: float = 0.0
## Time of day, in hours. 0.0 to 24.0
@export var time_of_day: float:
    get:
        return _time_of_day
    set(value):
        _time_of_day = value
        time_of_day_changed.emit(_time_of_day)

func format_time_of_day() -> String:
    var suffix = "AM" if time_of_day < 12 else "PM"

    var hours = int(time_of_day) % 12
    if hours == 0:
        hours = 12
    var minutes = int((time_of_day - int(time_of_day)) * 60)
    
    return "%02d:%02d %s" % [hours, minutes, suffix]

## If the day cycle is currently active.
@export var day_cycle_active: bool = true

func _process(delta):
    if day_cycle_active:
        # 1 second real-time is 2 minutes in-game time
        time_of_day += delta * (2.0 / 60.0)

        if time_of_day >= 17.0:
            # At 5 PM, the day cycle ends.
            time_of_day = 17.0
            day_cycle_active = false

func begin_day():
    day += 1
    time_of_day = 8.0  # Start at 8 AM
    day_cycle_active = true

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
