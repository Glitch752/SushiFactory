extends CheckBox

func _ready():
    button_pressed = InputSettingsSingleton.show_bind_hints

    toggled.connect(func(on):
        InputSettingsSingleton.show_bind_hints = on
    )
