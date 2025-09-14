extends Node2D

@export var data: ItemData

@onready var sprite = $ItemSprite

func _ready():
    if data:
        apply_data()

func apply_data():
    if is_node_ready():
        sprite.texture = data.item_sprite
        name = data.item_name

func get_description() -> String:
    return data.description

func get_take_sound() -> AudioStream:
    return preload("res://audio/miscTake1.wav")

func get_place_sound() -> AudioStream:
    return preload("res://audio/miscTake2.wav")