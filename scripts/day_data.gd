extends Resource

class_name DayData

enum OrderDifficulty {
    BASIC,
    MEDIUM,
    ADVANCED,
    EXPERT
}


## The mean interval at which customers enter, in game-hours.
## Days run from 9.0 to 17.0, so a value of 0.5 means roughly two customers every hour / 16 customers total.
## The actual interval is based on a normal distribution.
@export var customer_interval: float = 1.0

## The standard deviation of the customer interval, as a ratio of the mean.
var customer_interval_stddev_ratio: float = 0.2

## The mean patience of spawned customers, in game-minutes. Actual patience is based on a normal distribution.
@export var customer_patience: float = 120.0

## The standard deviation of customer patience, as a ratio of the mean.
var customer_patience_stddev: float = 0.3

## The absolute minimum customer patience, as a ratio of the mean.
## Just to ensure we don't have unreasonable outliers in the normal distribution.
## Is that actually likely to happen? Not really. Mathematically, the chance is super low, but this is easy to implement so meh
var customer_patience_min_ratio: float = 0.5

## The difficulty of orders that can be spawned this day.
## Probabilities are proportional to the number of difficulties listed.
@export var order_difficulties: Array[OrderDifficulty] = [OrderDifficulty.BASIC]



## Generates the next customer interval time (in GAME-HOURS) based on the day's normal distribution.
func next_customer_interval_time() -> float:
    var stddev = customer_interval * customer_interval_stddev_ratio
    return clamp(randfn(customer_interval, stddev), 0.01, customer_interval * 2.0)

## Generates the next customer patience (in GAME-HOURS, not minutes) based on the day's normal distribution.
func next_customer_patience() -> float:
    var patience = customer_patience / 60.0 # Game-minutes to hours
    var stddev = patience * customer_patience_stddev
    var min_patience = patience * customer_patience_min_ratio
    return clamp(randfn(patience, stddev), min_patience, patience * 2.0)