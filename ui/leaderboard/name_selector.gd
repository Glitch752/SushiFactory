extends HBoxContainer

var current_name: String = "AAA"
var selected_letter: int = 0

const LETTER_SET = "ABCDEFGHIJKLMNOPQRSTUVWXYZアイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン "

func _ready() -> void:
    focus_entered.connect(update_letters)
    focus_exited.connect(update_letters)

func update_letters():
    for i in range(3):
        var letter = get_child(i)
        var letter_label = letter.get_node("Label") as Label
        letter_label.text = current_name[i]
        var outline = letter.get_node("Outline") as Panel
        outline.visible = (i == selected_letter) and has_focus()

func _gui_input(event):
    if event.is_action_pressed("ui_left"):
        selected_letter = (selected_letter + 2) % 3
        update_letters()
    elif event.is_action_pressed("ui_right"):
        selected_letter = (selected_letter + 1) % 3
        update_letters()
    elif not event.is_released() and event.is_action("rotate_left"):
        var current_char = current_name[selected_letter]
        var index = LETTER_SET.find(current_char)
        index = (index - 1) % LETTER_SET.length()
        current_name = current_name.substr(0, selected_letter) + LETTER_SET[index] + current_name.substr(selected_letter + 1)
        update_letters()
    elif not event.is_released() and event.is_action("rotate_right"):
        var current_char = current_name[selected_letter]
        var index = LETTER_SET.find(current_char)
        index = (index + 1) % LETTER_SET.length()
        current_name = current_name.substr(0, selected_letter) + LETTER_SET[index] + current_name.substr(selected_letter + 1)
        update_letters()
    elif event.is_action_pressed("ui_accept"):
        emit_signal("name_selected", current_name)
