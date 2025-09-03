extends CharacterBody2D

## Speed in pixels per second.
@export_range(0, 1000) var speed := 240

func _physics_process(_delta: float) -> void:
	get_player_input()
	move_and_slide()

func get_player_input() -> void:
	# TODO: Should this be ui_*? Maybe we should create our own config
	var vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# TODO: Accelerate the player instead? This creates a lot of jerk.
	velocity = vector * speed
