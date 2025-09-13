extends Node

signal day_changed(new_day: int)
signal time_of_day_changed(new_time_of_day: float)

const OrderDifficulty = preload("res://scripts/day_data.gd").OrderDifficulty

@export var day_data: Array[DayData] = []

## The possible customer orders for each difficulty; just individual items for now
@export var possible_orders: Dictionary[OrderDifficulty, OrderPossibilities] = {}

func get_day_data(d: int) -> DayData:
    if d - 1 < day_data.size():
        return day_data[d - 1]
    else:
        return day_data[day_data.size() - 1]

func get_possible_orders(difficulty: OrderDifficulty) -> OrderPossibilities:
    if difficulty in possible_orders:
        return possible_orders[difficulty]
    else:
        return null

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

func format_duration(hours: float) -> String:
    var h = int(hours)
    var m = int((hours - h) * 60)
    if h > 0 and m > 0:
        return "%dh %dm" % [h, m]
    elif h > 0:
        return "%dh" % h
    else:
        return "%dm" % m

## If the day cycle is currently active.
@export var day_cycle_active: bool = true

## A conversion factor from real-time seconds to in-game hours.
## 1 second real-time is 2 minutes in-game time
const TIME_FACTOR = 2.0 / 60.0

func elapsed_world_time(delta: float) -> float:
    return delta * TIME_FACTOR

func _process(delta):
    if day_cycle_active:
        var previous_time = time_of_day

        time_of_day += delta * TIME_FACTOR

        if previous_time < 9.0 and time_of_day >= 9.0:
            # At 9 AM, the store opens.
            LevelInterfaceSingleton.notify_store_open()

            CustomerManagerSingleton.store_opened()

        if time_of_day >= 17.0:
            # At 5 PM, the day cycle ends.
            time_of_day = 17.0
            day_cycle_active = false
            LevelInterfaceSingleton.notify_store_closing()
            CustomerManagerSingleton.store_closed()

func begin_day():
    day += 1
    time_of_day = 8.0  # Start at 8 AM
    day_cycle_active = true

    LevelInterfaceSingleton.notify_day_started(day)

    CustomerManagerSingleton.begin_day(get_day_data(day))
