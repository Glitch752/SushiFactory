extends Resource

class_name EmailSendData

@export var sender: String
@export var subject: String
@export_multiline var body: String
@export var send_trigger: EmailSendTrigger
