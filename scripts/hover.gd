## Makes an object hover up and down subtly
extends Node2D

@export var hover_height := 1.0
@export var hover_speed := 1.5
var base_y := 0.0

func _ready():
    base_y = position.y
    set_process(true)

func _process(_delta):
    if visible:
        position.y = base_y + sin(Time.get_ticks_msec() / 1000.0 * hover_speed) * hover_height
