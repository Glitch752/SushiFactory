extends PanelContainer

@export var emailData: EmailData

var stylebox = StyleBoxFlat.new()

@export var color: Color
@export var colorHover: Color

func _ready():
    stylebox.content_margin_left = 16
    stylebox.content_margin_top = 2
    stylebox.content_margin_right = 16
    stylebox.content_margin_bottom = 2
    stylebox.bg_color = color
    
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
    
    mouse_entered.connect(mouse_enter)
    mouse_exited.connect(mouse_exit)
    
    add_theme_stylebox_override("panel", stylebox)

func mouse_enter():
    stylebox.bg_color = colorHover
    SoundManager.play_mouse_enter()
    
func mouse_exit():
    stylebox.bg_color = color

func _gui_input(event):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        SoundManager.play_pressed()
        get_viewport().set_input_as_handled()
        get_parent().open_email(emailData)
