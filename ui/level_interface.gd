extends Control

func _ready():
    LevelInterfaceSingleton.money_changed.connect(update_money_display)
    LevelInterfaceSingleton.day_changed.connect(update_day_display)
    LevelInterfaceSingleton.time_of_day_changed.connect(update_time_display)
    
    LevelInterfaceSingleton.interact_text_changed.connect(set_interact_text_shown)
    LevelInterfaceSingleton.info_description_changed.connect(set_info_description)

    update_money_display(LevelInterfaceSingleton.current_money)
    update_day_display(LevelInterfaceSingleton.day)
    update_time_display(LevelInterfaceSingleton.time_of_day)


## @param new_text The new text to display, or "" to keep the current text.
func set_interact_text_shown(txt_name: String, txt_show: bool, new_text: String):
    var interact_text = $InteractText
    var child = interact_text.get_node(txt_name)
    if child:
        if new_text != "":
            child.text = new_text
        child.visible = txt_show
    else:
        push_error("No interact text with name '%s'" % txt_name)

## @param text The new text to display, or null to hide the description.
func set_info_description(text: Variant):
    if text is String and text != "":
        $%MachineInfoLabel.text = text.strip_edges()
        $MachineInfo.visible = true
    else:
        $MachineInfo.visible = false

func update_money_display(money: int):
    $%MoneyLabel.text = "$" + str(money)

func update_day_display(day: int):
    $%DayLabel.text = "Day " + str(day)

func update_time_display(time_of_day: float):
    $%TimeLabel.text = LevelInterfaceSingleton.format_time_of_day()
    $%TimeProgress.value = time_of_day
