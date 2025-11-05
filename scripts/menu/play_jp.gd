extends "res://scripts/menu/play.gd"

func _on_pressed():
    LocalizationSingleton.set_lang("jp")
    
    super._on_pressed()


func _on_focus_entered() -> void:
    LocalizationSingleton.set_lang("jp")
