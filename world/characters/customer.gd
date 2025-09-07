extends AnimatableBody2D

@onready var sprites = [$SkinSprite, $BodySprite, $ShirtSprite]

var animations = ["walk_down", "walk_up", "walk_left", "walk_right"]

func _ready():
    # Randomly show either Hair0Sprite, Hair1Sprite, or neither (with a small probability)
    var chance = randi() % 9
    if chance < 4:
        $Hair0Sprite.visible = true
        $Hair1Sprite.visible = false
        sprites.append($Hair0Sprite)
    elif chance < 8:
        $Hair1Sprite.visible = true
        $Hair0Sprite.visible = false
        sprites.append($Hair1Sprite)
    else:
        $Hair0Sprite.visible = false
        $Hair1Sprite.visible = false

    animate_all(animations[randi() % animations.size()])

func animate_all(anim_name: String):
    for sprite in sprites:
        sprite.animation = anim_name
        sprite.play()
