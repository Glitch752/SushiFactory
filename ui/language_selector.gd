extends HBoxContainer


func _on_en_lang_button_pressed() -> void:
    LocalizationSingleton.set_lang("en")
    update_lang_buttons()

    $ENLangButton.grab_focus()

func _on_jp_lang_button_pressed() -> void:
    LocalizationSingleton.set_lang("jp")
    update_lang_buttons()

    $JPLangButton.grab_focus()

func update_lang_buttons():
    var lang = LocalizationSingleton.get_lang()
    print(lang)

    $ENLangButton.disabled = lang == "en_US"
    $JPLangButton.disabled = lang == "jp"

    $ENLangButton.focus_mode = FocusMode.FOCUS_NONE if $ENLangButton.disabled else FocusMode.FOCUS_ALL
    $JPLangButton.focus_mode = FocusMode.FOCUS_NONE if $JPLangButton.disabled else FocusMode.FOCUS_ALL
