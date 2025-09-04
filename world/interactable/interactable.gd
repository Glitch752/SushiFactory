extends Node2D

@onready var highlight = $InteractionHighlight

func _ready():
    $Area2D.add_to_group("interact_zone")
    add_user_signal("interacted")

func interact_show():
    highlight.visible = true

func interact_hide():
    highlight.visible = false

func interact():
    print("Must override interact in a subclass")
