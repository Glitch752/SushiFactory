extends Node

# See https://docs.godotengine.org/en/stable/tutorials/i18n/internationalizing_games.html

func _ready():
    var config = ConfigFile.new()
    var err = config.load("user://locale.cfg")
    if err != OK:
        return
    
    var language = config.get_value("locale", "language", "automatic")
    
    if language == "automatic":
        var preferred_language = OS.get_locale_language()
        TranslationServer.set_locale(preferred_language)
    else:
        TranslationServer.set_locale(language)

func set_lang(lang: String):
    var config = ConfigFile.new()
    var err = config.load("user://locale.cfg")
    if err != OK:
        return
    
    config.set_value("locale", "language", lang)
    TranslationServer.set_locale(lang)

    err = config.save("user://locale.cfg")
    if err != OK:
        push_error("Failed to save audio settings config: %s" % err)

func get_lang() -> String:
    return TranslationServer.get_locale()
