extends Node2D

func _ready():
    DayManagerSingleton.begin_day()

    $%EndDayZone.area_entered.connect(func(area):
        if area.is_in_group("player"):
            DayManagerSingleton.try_to_end_day()
    )
