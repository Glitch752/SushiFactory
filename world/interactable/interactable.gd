extends Node2D

@onready var highlight = $InteractionHighlight

func _ready():
    $Area2D.add_to_group("interact_zone")

## Can be overriden to turn off interaction depending on the situation
func can_interact():
    return true

func get_interact_explanation():
    return "interact"

func interact_show():
    highlight.visible = true

func interact_hide():
    highlight.visible = false

func interact():
    print("Must override interact in a subclass")
