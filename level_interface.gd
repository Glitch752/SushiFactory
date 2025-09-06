extends Control

func _ready():
    add_to_group("level_interface")


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
