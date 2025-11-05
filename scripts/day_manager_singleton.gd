extends Node

signal day_changed(new_day: int)
signal time_of_day_changed(new_time_of_day: float)

signal day_started(new_day: int, data: DayData, info_text: String)
signal store_opened()
signal store_closed()

const ShaderSceneTransition = preload("res://ui/ShaderSceneTransition.tscn")

const OrderDifficulty = preload("res://scripts/day_data.gd").OrderDifficulty

## The possible customer orders for each difficulty; just individual items for now
@export var possible_orders: Dictionary[OrderDifficulty, OrderPossibilities] = {}

var current_day_data: DayData = null

const MAX_DIFFICULTY: int = OrderDifficulty.EXPERT
const K_DIFF_PROGRESS: float = 0.15

const SIGMA_MIN: float = 0.1
const SIGMA_PEAK: float = 1.25
const SIGMA_A: float = 0.3
const SIGMA_B: float = 0.2

const INTERVAL_MAX: float = 1.0
const INTERVAL_MIN: float = 0.15
const INTERVAL_LAMBDA: float = 0.2
const INTERVAL_JITTER_RATIO = 0.15

const PATIENCE_MAX: float = 180.0
const PATIENCE_MIN: float = 45.0
const PATIENCE_LAMBDA: float = 0.2
const PATIENCE_JITTER_RATIO = 0.1

## Generates the current day data based on an increasing difficulty over time.
## For how the equations fit together, see this Desmos graph:
## https://www.desmos.com/calculator/dxh9onpg1q
func update_day_data() -> void:
    var d = day - 1

    # Convert the day to a continuous difficulty_progress in the range 0-MAX_DIFFICULTY
    var difficulty_progress: float = min(MAX_DIFFICULTY, (MAX_DIFFICULTY + 0.5) * (1 - exp(-K_DIFF_PROGRESS * d)))

    # Sigma that grows then shrinks over time so the difficulty distribution concentrates
    # I made up this formula; it's not derived from anything lmao
    var sigma: float = SIGMA_MIN + d * (SIGMA_PEAK - SIGMA_MIN) * (1 - exp(-SIGMA_A*d)) * exp(-SIGMA_B * pow(d, 1.5))

    # Discrete gaussian difficulty weights
    var difficulty_weights: Dictionary[OrderDifficulty, float] = {}
    var total_weight: float = 0.0
    for diff in OrderDifficulty.values():
        var weight = exp(
            -pow(float(diff) - difficulty_progress, 2) / (2 * pow(sigma, 2))
        ) # Gaussian formula
        difficulty_weights[diff] = weight
        total_weight += weight
    
    # Normalize
    for diff in difficulty_weights.keys():
        difficulty_weights[diff] /= total_weight
    
    # Interval is exponential decay toward the minimum
    var customer_interval = INTERVAL_MIN + (INTERVAL_MAX - INTERVAL_MIN) * exp(-INTERVAL_LAMBDA * d)
    customer_interval *= randf_range(1.0 - INTERVAL_JITTER_RATIO, 1.0 + INTERVAL_JITTER_RATIO)

    # Patience is exponential decay toward the minimum
    var customer_patience = PATIENCE_MIN + (PATIENCE_MAX - PATIENCE_MIN) * exp(-PATIENCE_LAMBDA * d)
    customer_patience *= randf_range(1.0 - PATIENCE_JITTER_RATIO, 1.0 + PATIENCE_JITTER_RATIO)

    var day_data = DayData.new()
    day_data.customer_interval = customer_interval
    day_data.customer_patience = round(customer_patience)
    day_data.difficulty_probabilities = difficulty_weights
    
    current_day_data = day_data


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
        update_day_data()

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

static func format_duration(hours: float) -> String:
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

## The previous time. Used to detect time transitions.
var previous_time = 0.0
func _process(delta):
    if day_cycle_active:
        time_of_day += delta * TIME_FACTOR

        if previous_time < 9.0 and time_of_day >= 9.0:
            # At 9 AM, the restaurant opens.
            store_opened.emit()

        if previous_time < 17.0 and time_of_day >= 17.0:
            # At 5 PM, the day cycle ends.
            time_of_day = 17.0
            day_cycle_active = false
            store_closed.emit()
        
        previous_time = time_of_day

## Generates the day opening info, e.g:
## [b]Expected customer rate[/b]: [color=#ffff99]10/hr[/color]
## [b]Customer patience[/b]: [color=#ffff99]2hrs[/color]
## [b]Order difficulties[/b]: [color=#99ff88]basic[/color], [color=#ff9988]advanced[/color]
func generate_day_opening_info():
    var customerRate = 1.0 / current_day_data.customer_interval
    
    var rateColor = "#ff9988" if customerRate >= 6 else "#ffff99" if customerRate >= 3 else "#99ff88"
    var info = "[b]Expected customer rate[/b]: [color=%s]%.1f/hr[/color]\n" % [rateColor, customerRate]

    var patienceColor = "#ff9988" if current_day_data.customer_patience <= 30.0 else "#ffff99" if current_day_data.customer_patience <= 60.0 else "#99ff88"
    info += "[b]Customer patience[/b]: [color=%s]%sm[/color]\n" % [patienceColor, round(current_day_data.customer_patience / 5) * 5]

    var difficulties = []
    for diff in current_day_data.difficulty_probabilities.keys():
        var prob = current_day_data.difficulty_probabilities[diff]
        if prob < 0.02:
            continue
        
        var possibleOrders = DayManagerSingleton.get_possible_orders(diff)
        difficulties.append("[color=#%s]%s%% %s[/color]" % [possibleOrders.color.to_html(), int(prob * 100), possibleOrders.name.to_lower()])
    
    info += "[b]Order difficulties[/b]: %s" % ", ".join(difficulties)
    
    return info

func begin_day():
    day += 1
    time_of_day = 8.0  # Start at 8 AM
    previous_time = 0.0
    day_cycle_active = true

    day_started.emit(day, current_day_data, generate_day_opening_info())

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
