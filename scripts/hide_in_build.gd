extends Label

func _ready():
    if ArcadeMode.is_arcade_mode():
        visible = false
