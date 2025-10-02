extends CharacterBody2D

## Speed in pixels per second.
@export var movement_speed = 150
@export var animation_base_speed = 100

@export var automation_objects_tilemap: AutomationObjectsTilemap

# We only have player animations for the cardinal directions, but the player
# movement is analog. This stores the last direction that we had a cardinal
# direction input for.
var animation_direction: Vector2 = Vector2.DOWN
var facing: Vector2 = Vector2.DOWN
var latest_keyboard_input_direction = Vector2.ZERO

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
    get_player_input(delta)
    move_and_slide()
    
    play_footsteps(delta)
    
    update_animation()

func _ready():
    $%MovementInteractionZone.add_to_group("open_doors")
    $%MovementInteractionZone.add_to_group("player")
    
    animated_sprite.play()

func get_player_input(delta) -> void:
    if not InputTargetSingleton.is_active(InputTargetSingleton.InputTarget.PlayerMovement):
        velocity = Vector2.ZERO
        return

    var vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var target_velocity = vector * movement_speed
    var acceleration = 1200.0

    if Input.is_action_just_pressed("move_left"):
        latest_keyboard_input_direction = Vector2.LEFT
    elif Input.is_action_just_pressed("move_right"):
        latest_keyboard_input_direction = Vector2.RIGHT
    elif Input.is_action_just_pressed("move_up"):
        latest_keyboard_input_direction = Vector2.UP
    elif Input.is_action_just_pressed("move_down"):
        latest_keyboard_input_direction = Vector2.DOWN

    velocity = velocity.move_toward(target_velocity, acceleration * delta)

@onready var footstepSounds = $FootstepSounds
@onready var floorTileMap: TileMapLayer = $"../../FloorTileMap"
var footstep_timer: float = 0.0
func play_footsteps(delta):
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

func update_animation() -> void:
    var effective_velocity = velocity

    if effective_velocity != Vector2.ZERO:
        if abs(effective_velocity.x) != abs(effective_velocity.y):
            animation_direction = effective_velocity.normalized()
        elif animation_direction == Vector2.ZERO:
            animation_direction = Vector2(0, effective_velocity.y)
        elif latest_keyboard_input_direction != Vector2.ZERO:
            animation_direction = latest_keyboard_input_direction
            latest_keyboard_input_direction = Vector2.ZERO
    else:
        animation_direction = Vector2.ZERO
        # animated_sprite.animation = "idle"
        animated_sprite.speed_scale = 0
        animated_sprite.frame = 0
        return

    animated_sprite.speed_scale = effective_velocity.length() / animation_base_speed
    
    if abs(animation_direction.x) > abs(animation_direction.y):
        if animation_direction.x > 0:
            animated_sprite.animation = "walk_right"
            facing = Vector2.RIGHT
        else:
            animated_sprite.animation = "walk_left"
            facing = Vector2.LEFT
    else:
        if animation_direction.y > 0:
            animated_sprite.animation = "walk_down"
            facing = Vector2.DOWN
        else:
            animated_sprite.animation = "walk_up"
            facing = Vector2.UP
