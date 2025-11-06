extends Resource

class_name EmailSendData

@export var sender: String:
    get:
        return tr(sender)
@export var subject: String:
    get:
        return tr(subject)
@export_multiline var body: String:
    get:
        return tr(body)
@export var send_trigger: EmailSendTrigger
