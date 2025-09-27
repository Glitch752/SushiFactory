@tool

extends StackContainer

# TODO: Make this dynamic based on what device is currently connected

const InteractionAction = preload("res://world/interactable/interactable.gd").InteractionAction

enum InputAction {}

const CUSTOM_KEYCODE_REPLACEMENTS: Dictionary[String, String] = {
    "QuoteLeft": "`",
    "Escape": "Esc"
}

static func customize_keycode(keycode: String) -> String:
    for oldKey in CUSTOM_KEYCODE_REPLACEMENTS.keys():
        keycode = keycode.replace(oldKey, CUSTOM_KEYCODE_REPLACEMENTS[oldKey])
    return keycode

@warning_ignore("enum_variable_without_default")
@export var action: InputAction:
    set(val):
        action = val
        update_defaults()
@export var placeholderText: String = "Secondary interact":
    set(val):
        placeholderText = val
        update_defaults()

func get_input_properties() -> Array[Dictionary]:
    # We need to use ProjectSettings here because InputMap returns the editor's internal actions.
    # From the documentation:
    # > Note: When used in the editor (e.g. a tool script or EditorPlugin),
    # > this method will return [editor actions]. If you want to access your
    # > project's input binds from the editor, read the input/* settings from ProjectSettings.
    var input_properties = ProjectSettings.get_property_list().filter(func(pi):
        return pi["name"].begins_with("input/")
    )
    input_properties.sort_custom(func(a, b):
        return (a["name"] as String).casecmp_to(b["name"]) < 0
    )

    return input_properties

func _validate_property(property: Dictionary):
    if property.name == "action":
        var actions = ""
        
        for pi in get_input_properties():
            var actionName = pi.name.substr(pi.name.find("/") + 1)
            actions += actionName + ","
        property.hint_string = actions.substr(0, actions.length() - 1)

@onready var keyLabel: Label = $%KeyLabel
@onready var infoText: Label = $%InfoText
@onready var progress: ProgressBar = $%TimedInteractProgress

@export var direction: LayoutDirection = LayoutDirection.LAYOUT_DIRECTION_LTR:
    set(val):
        direction = val
        update_defaults()

## If this hint isn't necessary, it won't be shown when hints are disabled in the pause menu.
@export var is_necessary: bool = true

func _ready():
    update_defaults()

func update_defaults():
    if !is_node_ready():
        return
    
    var action_property = get_input_properties().get(action)
    if action_property == null:
        $%KeyLabel.text = "ERR"
    else:
        var action_data = ProjectSettings[action_property["name"]]
        var suitable_event_shortnames = action_data["events"].filter(func(ev: Variant):
            if ev is InputEventKey:
                return true
            elif ev is InputEventJoypadButton:
                return true
            else:
                return false
        ).map(func(ev: InputEvent):
            if ev is InputEventKey:
                var keystr = OS.get_keycode_string((ev as InputEventKey).get_keycode_with_modifiers())
                keystr += OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(ev.physical_keycode))
                return customize_keycode(keystr)
            elif ev is InputEventJoypadButton:
                return str((ev as InputEventJoypadButton).button_index)
            else:
                return "idk"
        )
        print(suitable_event_shortnames)

        if len(suitable_event_shortnames) == 0:
            $%KeyLabel.text = "NONE"
        else:
            $%KeyLabel.text = suitable_event_shortnames[0]
    
    $%InfoText.text = placeholderText
    $%TimedInteractProgress.visible = false
    
    $%Layout.layout_direction = direction

func update(action: InteractionAction):
    if action == null:
        visible = false
        progress.visible = false
        return
    
    visible = true
    
    var nameText = action.name
    if action.time_required > 0.0:
        nameText += " (%.1fs)" % (action.time_required - action.current_time)
    infoText.text = nameText
    
    if action.time_required > 0.0:
        progress.visible = true
        progress.value = ease(action.current_time / action.time_required, -1.2)
    else:
        progress.visible = false
