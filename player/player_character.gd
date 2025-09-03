extends CharacterBody2D

## Speed in pixels per second.
@export var movement_speed := 150
@export var animation_base_speed := 100

# We only have player animations for the cardinal directions, but the player
# movement is analog. This stores the last direction that we had a cardinal
# direction input for.
var animation_direction: Vector2 = Vector2.DOWN

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	get_player_input()
	move_and_slide()
	
	update_animation()

func _ready():
	animated_sprite.play()

func get_player_input() -> void:
	# TODO: Should this be ui_*? Maybe we should create our own config
	var vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target_velocity = vector * movement_speed
	var acceleration = 1200.0
	velocity = velocity.move_toward(target_velocity, acceleration * get_physics_process_delta_time())

func update_animation() -> void:
	var effective_velocity = velocity

	if effective_velocity != Vector2.ZERO:
		if abs(effective_velocity.x) != abs(effective_velocity.y):
			animation_direction = effective_velocity.normalized()
		elif animation_direction == Vector2.ZERO:
			animation_direction = Vector2(0, effective_velocity.y)
	else:
		animation_direction = Vector2.ZERO
		animated_sprite.animation = "idle"
		animated_sprite.speed_scale = 1
		return

	animated_sprite.speed_scale = effective_velocity.length() / animation_base_speed
	
	if abs(animation_direction.x) > abs(animation_direction.y):
		if animation_direction.x > 0:
			animated_sprite.animation = "walk_right"
		else:
			animated_sprite.animation = "walk_left"
	else:
		if animation_direction.y > 0:
			animated_sprite.animation = "walk_down"
		else:
			animated_sprite.animation = "walk_up"
