@tool

extends HBoxContainer

func locale_long_number(num: int) -> String:
    var str_num = str(num)
    var result = ""
    var count = 0
    for i in range(str_num.length() - 1, -1, -1):
        result = str_num[i] + result
        count += 1
        if count % 3 == 0 and i != 0:
            result = "," + result
    # i lied. not a locale long number
    return result

@onready var name_label = $Name
@onready var days_label = $Days
@onready var money_label = $Money

@export var entry_name: String = "":
    set(value):
        entry_name = value
        if name_label:
            name_label.text = value
@export var days: int = 0:
    set(value):
        days = value
        if days_label:
            days_label.text = str(value)
@export var money: int = 0:
    set(value):
        money = value
        if money_label:
            money_label.text = "¥" + locale_long_number(value)

func _ready() -> void:
    name_label.text = entry_name
    days_label.text = str(days)
    money_label.text = "¥" + locale_long_number(money)
