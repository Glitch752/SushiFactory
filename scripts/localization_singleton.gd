extends Node

# See https://docs.godotengine.org/en/stable/tutorials/i18n/internationalizing_games.html

func _ready():
    var language = "automatic"
    # TODO: load language from the user settings file
    
    if language == "automatic":
        var preferred_language = OS.get_locale_language()
        TranslationServer.set_locale(preferred_language)
    else:
        TranslationServer.set_locale(language)
