extends "res://scripts/menu/play.gd"

func _ready() -> void:
    self.grab_focus()

func _on_pressed():
    LocalizationSingleton.set_lang("en")
    
    super._on_pressed()

func _on_focus_entered() -> void:
    LocalizationSingleton.set_lang("en")
