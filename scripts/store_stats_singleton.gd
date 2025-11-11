extends Node

func _ready() -> void:
    DayManagerSingleton.day_started.connect(_day_started)
    CustomerManagerSingleton.customer_angered.connect(anger_customer)
    CustomerManagerSingleton.customer_satisfied.connect(satisfy_customer)


## Money

signal money_changed(new_money: int)
## This is in Yen! 1 usd ~= 150 yen.
@export var money: int = 0:
    set(value):
        money = value
        money_changed.emit(value)


## Reputation

var max_reputation: int = 5

signal game_over()

signal reputation_changed(new_reputation: int)
@export var reputation: int = 5:
    set(value):
        if value == reputation:
            return
        
        reputation = value
        reputation_changed.emit(value)

        if reputation <= 0:
            game_over.emit()


## Logic

@warning_ignore("unused_parameter")
func _day_started(new_day: int, data: DayData, info_text: String) -> void:
    if reputation < max_reputation:
        reputation += 1

func anger_customer() -> void:
    if reputation <= 0:
        return
    
    reputation -= 1

func satisfy_customer(difficulty: OrderPossibilities) -> void:
    pay_for_dish(difficulty)

func pay_for_dish(difficulty: OrderPossibilities):
    money += difficulty.pay


func _play_reset() -> void:
    money = 0
    reputation = max_reputation


# For debugging only!
func _unhandled_input(event):
    # Disable in builds in case I forget :)
    if OS.has_feature("release") or OS.has_feature("production"):
        return

    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_9:
            reputation -= 1
