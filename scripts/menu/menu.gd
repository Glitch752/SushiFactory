extends Control

@onready var path: Path2D = $%MenuBeltPath
@onready var timer: Timer = $Timer

const PlateScene = preload("res://world/items/Plate.tscn")

@export var menu_items: Array[ItemData] = []

func _ready():
    timer.start()
    timer.timeout.connect(spawn_item)

func spawn_item():
    var path_follower = PathFollow2D.new()
    path_follower.progress = 0
    path_follower.rotates = false

    var plate = PlateScene.instantiate()
    plate.position = Vector2.ONE * 3 # yay for magic numbers
    plate.scale = Vector2.ONE * 8

    for i in range(1 + randi() % 3):
        plate.add_to_plate(menu_items[randi() % menu_items.size()], true)

    path_follower.add_child(plate)
    path.add_child(path_follower)

    timer.wait_time = 0.25 + randf() * 2.0
    timer.start()

func _process(delta):
    for follower in path.get_children():
        if follower.progress + delta * 480 >= path.curve.get_baked_length():
            follower.queue_free()
        else:
            follower.progress += delta * 480
