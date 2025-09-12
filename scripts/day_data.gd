extends Resource

class_name DayData

enum OrderDifficulty {
    BASIC,
    MEDIUM,
    ADVANCED,
    EXPERT
}

## The interval at which customers enter, in game-hours.
## Days run from 9.0 to 17.0, so a value of 1.0 means one customer every hour / 8 customers total.
@export var customer_interval: float = 1.0
## The patience of spawned customers, in seconds.
@export var customer_patience: float = 120.0

## The difficulty of orders that can be spawned this day.
## Probabilities are proportional to the number of difficulties listed.
@export var order_difficulties: Array[OrderDifficulty] = [OrderDifficulty.BASIC]