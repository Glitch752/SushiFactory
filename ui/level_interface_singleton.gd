extends Node

const InteractionData = preload("res://world/interactable/interactable.gd").InteractionData

signal money_changed(new_money: int)
signal interaction_data_changed(data: InteractionData)

var _current_money: int = 0
@export var current_money: int:
    get:
        return _current_money
    set(value):
        _current_money = value
        money_changed.emit(_current_money)

func update_interactable(node: InteractionData):
    interaction_data_changed.emit(node)

func clear_interactable():
    interaction_data_changed.emit(null)
