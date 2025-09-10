extends Label

func _ready():
    DayManagerSingleton.time_of_day_changed.connect(update_time)

func update_time(_time_of_day: float):
    text = DayManagerSingleton.format_time_of_day()
