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

## Parses the email's content.
## Emails can contain structured tagging that causes certain sections to be included or excluded based on game state.
## Currently, this is just blocks inside `[reputation={high,medium,low}] ... [/reputation]`.
func parse_email_content(content: String) -> String:
    var reputation = ""
    if StoreStatsSingleton.reputation >= int(float(StoreStatsSingleton.max_reputation) * 2 / 3):
        reputation = "high"
    elif StoreStatsSingleton.reputation >= int(float(StoreStatsSingleton.max_reputation) / 3):
        reputation = "medium"
    else:
        reputation = "low"
    
    var lines = content.split("\n")
    var output_lines = []
    var inside_reputation_block = false
    var block_reputation = ""
    
    # This logic isn't perfect, but meh. I don't care about general handling yet, it just needs to work for the few cases I put it through
    for line in lines:
        var rep_block_start = line.find("[reputation=")
        var rep_block_end = line.find("[/reputation]")
        if rep_block_start != -1:
            # Parse the reputation value
            var start_idx = line.find("=") + 1
            var end_idx = line.find("]", start_idx)
            block_reputation = line.substr(start_idx, end_idx - start_idx)
            inside_reputation_block = true
            continue
        elif rep_block_end != -1:
            inside_reputation_block = false
            block_reputation = ""
            continue

        if inside_reputation_block:
            if block_reputation == reputation or block_reputation == str(StoreStatsSingleton.reputation):
                output_lines.append(line)
        elif not inside_reputation_block:
            output_lines.append(line)
    
    return "\n".join(output_lines)

func send_email(email_data: EmailSendData):
    var new_email = EmailData.new()
    new_email.sender = email_data.sender
    new_email.subject = email_data.subject
    new_email.body = parse_email_content(email_data.body)
    new_email.sent = "Day %d, %s" % [DayManagerSingleton.day, DayManagerSingleton.format_time_of_day()]

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
