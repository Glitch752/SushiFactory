extends Label

func _ready():
    if OS.has_feature("build"):
        visible = false
