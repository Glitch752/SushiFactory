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
        if preferred_language.starts_with("jp"):
            preferred_language = "jp"
        else:
            preferred_language = "en"
        TranslationServer.set_locale(preferred_language)
    else:
        TranslationServer.set_locale(language)

func set_lang(lang: String):
    var config = ConfigFile.new()
    var err = config.load("user://locale.cfg")
    if err != OK and err != ERR_FILE_NOT_FOUND:
        push_warning("Failed to load locale config: %s" % err)
        return
    
    config.set_value("locale", "language", lang)
    TranslationServer.set_locale(lang)

    print("Language set to " + lang)
    print("Locale server recognizes locale as " + TranslationServer.get_locale())

    err = config.save("user://locale.cfg")
    if err != OK:
        push_error("Failed to save locale config: %s" % err)

func get_lang() -> String:
    return TranslationServer.get_locale()
