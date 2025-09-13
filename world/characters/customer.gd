extends AnimatableBody2D

@onready var sprites = [$SkinSprite, $BodySprite, $ShirtSprite]

var previous_position: Vector2

@export var animation_base_speed = 80
    
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

func _physics_process(delta: float):
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
    
    play_footsteps(delta, velocity)

@onready var footstepSounds = $FootstepSounds
@onready var floorTileMap: TileMapLayer = $"../../FloorTileMap"
var footstep_timer: float = 0.0
func play_footsteps(delta: float, velocity: Vector2):
    if velocity.length_squared() > 0:
        if footstep_timer <= 0.0 and not footstepSounds.playing:
            var floor_pitch: float = 0.0
            if floorTileMap:
                var foot_position = global_position + Vector2(0, 15)
                var cell = floorTileMap.local_to_map(floorTileMap.to_local(foot_position))
                var tile = floorTileMap.get_cell_tile_data(cell)
                floor_pitch = tile.get_custom_data("floor_step_pitch")
            footstepSounds.pitch_scale = randf_range(0.8, 1.2) + floor_pitch
            footstepSounds.play()
            footstep_timer = min(0.25, 1.0 / velocity.length() * 100)
        footstep_timer -= delta

func animate_all(anim_name: String, speed_scale: float = 1.0):
    for sprite in sprites:
        sprite.animation = anim_name
        sprite.speed_scale = speed_scale
        sprite.play()
