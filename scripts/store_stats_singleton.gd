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

signal reputation_changed(new_reputation: int)
@export var reputation: int = 5:
    set(value):
        reputation = value
        reputation_changed.emit(value)

        if reputation <= 0:
            # TODO: lose screen
            print("you lose or something")


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