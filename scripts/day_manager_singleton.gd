extends Node

signal day_changed(new_day: int)
signal time_of_day_changed(new_time_of_day: float)

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

    CustomerManagerSingleton.begin_day()
