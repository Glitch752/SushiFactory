extends CheckBox

func _ready():
    toggled.connect(_update_ui)

func _update_ui(on: bool):
    pass
