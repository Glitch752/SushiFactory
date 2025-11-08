extends Label

func _ready():
    if OS.has_feature("arcade"):
        visible = false
