extends PanelContainer

@export var emailData: EmailData

func _ready():
    $%SenderName.text = emailData.sender
    $%Subject.text = emailData.subject
    $%SentTime.text = emailData.sent

    var text_color = Color.GRAY if emailData.is_read else Color.WHITE

    $%SenderName.label_settings = $%SenderName.label_settings.duplicate()
    $%SenderName.label_settings.font_color = text_color

    $%Subject.label_settings = $%Subject.label_settings.duplicate()
    $%Subject.label_settings.font_color = text_color

    $%SentTime.label_settings = $%SentTime.label_settings.duplicate()
    $%SentTime.label_settings.font_color = text_color

func _gui_input(event):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        get_viewport().set_input_as_handled()
        get_parent().open_email(emailData)
