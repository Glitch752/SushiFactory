extends TextureRect

func _ready():
    update_visible()
    EmailSystem.unread_status_changed.connect(update_visible)

func update_visible():
    visible = EmailSystem.has_unread_emails
