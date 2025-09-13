extends Node

signal day_changed(new_day: int)
signal time_of_day_changed(new_time_of_day: float)

signal day_started(new_day: int, data: DayData, info_text: String)
signal store_opened()
signal store_closed()

const ShaderSceneTransition = preload("res://ui/ShaderSceneTransition.tscn")

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
            # At 9 AM, the restaurant opens.
            store_opened.emit()

        if time_of_day >= 17.0:
            # At 5 PM, the day cycle ends.
            time_of_day = 17.0
            day_cycle_active = false
            store_closed.emit()

## Generates the day opening info, e.g:
## [b]Expected customer rate[/b]: [color=#ffff99]10/hr[/color]
## [b]Customer patience[/b]: [color=#ffff99]2hrs[/color]
## [b]Order difficulties[/b]: [color=#99ff88]basic[/color], [color=#ff9988]advanced[/color]
func generate_day_opening_info(for_day: int):
    var data: DayData = get_day_data(for_day)
    var customerRate = 1.0 / data.customer_interval
    
    var rateColor = "#ff9988" if customerRate >= 10 else "#ffff99" if customerRate >= 5 else "#99ff88"
    var info = "[b]Expected customer rate[/b]: [color=%s]%d/hr[/color]\n" % [rateColor, customerRate]

    var patienceColor = "#ff9988" if data.customer_patience <= 30.0 else "#ffff99" if data.customer_patience <= 60.0 else "#99ff88"
    info += "[b]Customer patience[/b]: [color=%s]%sm[/color]\n" % [patienceColor, int(data.customer_patience)]

    var difficulties = []
    for diff in data.order_difficulties:
        var possibleOrders = DayManagerSingleton.get_possible_orders(diff)
        difficulties.append("[color=#%s]%s[/color]" % [possibleOrders.color.to_html(), possibleOrders.name.to_lower()])
    
    info += "[b]Order difficulties[/b]: %s" % ", ".join(difficulties)
    
    return info

func begin_day():
    day += 1
    time_of_day = 8.0  # Start at 8 AM
    day_cycle_active = true

    day_started.emit(day, get_day_data(day), generate_day_opening_info(day))

## Try to end the day. The day may only end after 5 PM and if there are no customers left.
func try_to_end_day():
    if time_of_day >= 17.0 and CustomerManagerSingleton.all_customers_left():
        day_cycle_active = false # It shouldn't be anyways

        var transition = ShaderSceneTransition.instantiate()
        get_tree().root.add_child(transition)
        await transition.wipe_to_black()

        begin_day()

        await transition.wipe_from_black()
        transition.queue_free()

        return true
    return false

# For debugging only!
func _unhandled_input(event):
    # Disable in builds in case I forget :)
    if OS.has_feature("release") or OS.has_feature("production"):
        return

    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_0:
            time_of_day = min(time_of_day + 1.0, 17.0)
