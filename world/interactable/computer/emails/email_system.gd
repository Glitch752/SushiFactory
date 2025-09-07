extends Node

@export var email_send_data: Array[EmailSendData]

var unsent_emails: Array[EmailSendData] = []
var inbox: Array[EmailData] = []

signal inbox_updated

## We split trigger updates across frames to avoid performance regressions with lots of emails  
## Does this actually matter? I don't know, probably not.
var processed_trigger_idx = 0

func _ready():
    unsent_emails = email_send_data.duplicate()

func _process(_delta):
    if unsent_emails.size() == 0:
        return

    # Process one email trigger per frame
    var email_data = unsent_emails[processed_trigger_idx]
    if email_data.send_trigger.should_send():
        unsent_emails.remove_at(processed_trigger_idx)
        processed_trigger_idx -= 1
        send_email(email_data)

    processed_trigger_idx += 1
    if processed_trigger_idx >= unsent_emails.size():
        processed_trigger_idx = 0

func send_email(email_data: EmailSendData):
    var new_email = EmailData.new()
    new_email.sender = email_data.sender
    new_email.subject = email_data.subject
    new_email.body = email_data.body
    new_email.sent = "Day %d, %s" % [LevelInterfaceSingleton.day, LevelInterfaceSingleton.format_time_of_day()]

    inbox.push_front(new_email)

    update_unread_status()

    inbox_updated.emit()

var has_unread_emails: bool = false
signal unread_status_changed()

func update_unread_status():
    var previous_status = has_unread_emails
    has_unread_emails = false
    for email in inbox:
        if not email.is_read:
            has_unread_emails = true
            break
    if previous_status != has_unread_emails:
        unread_status_changed.emit()
