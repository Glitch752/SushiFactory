extends VBoxContainer

var EmailTemplate = preload("res://world/interactable/computer/emails/EmailTemplate.tscn")

func _ready():
    EmailSystem.inbox_updated.connect(update_list)
    update_list()

func update_list():
    clear_list()

    for email in EmailSystem.inbox:
        var email_entry = EmailTemplate.instantiate()
        email_entry.emailData = email
        add_child(email_entry)

func clear_list():
    for child in get_children():
        child.queue_free()

func open_email(emailData: EmailData):
    emailData.is_read = true
    EmailSystem.update_unread_status()
    update_list()

    $%ContentSubject.text = emailData.subject
    $%ContentSender.text = "From: " + emailData.sender
    $%ContentSentTime.text = emailData.sent
    $%Content.text = emailData.body

    $%EmailListMargin.visible = false
    $%EmailContent.visible = true
