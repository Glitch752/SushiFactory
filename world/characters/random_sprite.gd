extends AnimatedSprite2D

@export var choices: Array[SpriteFrames] = []

func _ready():
    if choices.size() > 0:
        var choice = choices[randi() % choices.size()]
        sprite_frames = choice
