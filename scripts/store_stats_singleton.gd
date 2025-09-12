extends Node

signal money_changed(new_money: int)

@export var current_money: int = 0:
    set(value):
        current_money = value
        money_changed.emit(value)

signal reputation_changed(new_reputation: int)

var max_reputation: int = 5

@export var current_reputation: int = 0:
    set(value):
        current_reputation = value
        reputation_changed.emit(value)