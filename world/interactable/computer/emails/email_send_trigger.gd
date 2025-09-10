extends Resource

class_name EmailSendTrigger

@export var day: int = 0
@export var time: float = 8.0

func should_send():
    return DayManagerSingleton.day >= day and DayManagerSingleton.time_of_day >= time
