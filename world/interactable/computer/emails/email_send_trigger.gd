extends Resource

class_name EmailSendTrigger

@export var day: int = 0
@export var time: float = 8.0

func should_send():
    return LevelInterfaceSingleton.day >= day and LevelInterfaceSingleton.time_of_day >= time
