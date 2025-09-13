extends Node

signal money_changed(new_money: int)

@export var money: int = 0:
    set(value):
        money = value
        money_changed.emit(value)

signal reputation_changed(new_reputation: int)

var max_reputation: int = 5

@export var reputation: int = 5:
    set(value):
        reputation = value
        reputation_changed.emit(value)