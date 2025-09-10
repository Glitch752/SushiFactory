extends AnimatableBody2D

@onready var sprites = [$SkinSprite, $BodySprite, $ShirtSprite]

var previous_position: Vector2

@export var animation_base_speed = 100
    
func _ready():
    $%MovementInteractionZone.add_to_group("open_doors")
    
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

func _physics_process(delta):
    # Find the direction we're moving in based on velocity
    if previous_position == null:
        previous_position = global_position
    
    var velocity = (global_position - previous_position) / delta
    previous_position = global_position
    
    if velocity.length() > 0:
        var speed = velocity.length() / animation_base_speed
        var angle = velocity.angle()
        if abs(angle) < PI / 4:
            animate_all("walk_right", speed)
        elif abs(angle) > 3 * PI / 4:
            animate_all("walk_left", speed)
        elif angle > 0:
            animate_all("walk_down", speed)
        else:
            animate_all("walk_up", speed)
    else:
        for sprite in sprites:
            sprite.stop()
            sprite.frame = 0

func animate_all(anim_name: String, speed_scale: float = 1.0):
    for sprite in sprites:
        sprite.animation = anim_name
        sprite.speed_scale = speed_scale
        sprite.play()
