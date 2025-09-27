@tool

extends StackContainer

# TODO: Make this dynamic based on what device is currently connected

const InteractionAction = preload("res://world/interactable/interactable.gd").InteractionAction

@warning_ignore("enum_variable_without_default")
@export_custom(PROPERTY_HINT_ENUM_SUGGESTION, "") var action: String = "":
    set(val):
        action = val
        update_defaults()
@export var placeholderText: String = "Secondary interact":
    set(val):
        placeholderText = val
        update_defaults()

@export var force_hide: bool = false:
    set(val):
        force_hide = val
        update_defaults()

enum InputAction {}

const CUSTOM_KEYCODE_REPLACEMENTS: Dictionary[String, String] = {
    "QuoteLeft": "`",
    "Escape": "Esc"
}

const SONY_JOY_BUTTON_MAP: Dictionary[JoyButton, String] = {
    JoyButton.JOY_BUTTON_A: "✕",
    JoyButton.JOY_BUTTON_B: "○",
    JoyButton.JOY_BUTTON_X: "□",
    JoyButton.JOY_BUTTON_Y: "△",
    JoyButton.JOY_BUTTON_BACK: "Select",
    JoyButton.JOY_BUTTON_START: "Start",
    JoyButton.JOY_BUTTON_MISC1: "PS"
}
const XBOX_JOY_BUTTON_MAP: Dictionary[JoyButton, String] = {
    JoyButton.JOY_BUTTON_A: "A",
    JoyButton.JOY_BUTTON_B: "B",
    JoyButton.JOY_BUTTON_X: "X",
    JoyButton.JOY_BUTTON_Y: "Y",
    JoyButton.JOY_BUTTON_BACK: "Back",
    JoyButton.JOY_BUTTON_START: "Menu",
    JoyButton.JOY_BUTTON_MISC1: "Share"
}
const NINTENDO_JOY_BUTTON_MAP: Dictionary[JoyButton, String] = {
    JoyButton.JOY_BUTTON_A: "B",
    JoyButton.JOY_BUTTON_B: "A",
    JoyButton.JOY_BUTTON_X: "Y",
    JoyButton.JOY_BUTTON_Y: "X",
    JoyButton.JOY_BUTTON_BACK: "-",
    JoyButton.JOY_BUTTON_START: "+",
    JoyButton.JOY_BUTTON_MISC1: "Capture"
}

const FALLBACK_JOY_BUTTON_MAP: Dictionary[JoyButton, String] = {
    JoyButton.JOY_BUTTON_GUIDE: "Guide",
    JoyButton.JOY_BUTTON_LEFT_STICK: "L◉",
    JoyButton.JOY_BUTTON_RIGHT_STICK: "R◉",
    JoyButton.JOY_BUTTON_LEFT_SHOULDER: "L1",
    JoyButton.JOY_BUTTON_RIGHT_SHOULDER: "R1",
    JoyButton.JOY_BUTTON_DPAD_UP: "D↑",
    JoyButton.JOY_BUTTON_DPAD_DOWN: "D↓",
    JoyButton.JOY_BUTTON_DPAD_LEFT: "D←",
    JoyButton.JOY_BUTTON_DPAD_RIGHT: "D→",
    JoyButton.JOY_BUTTON_PADDLE1: "P1",
    JoyButton.JOY_BUTTON_PADDLE2: "P2",
    JoyButton.JOY_BUTTON_PADDLE3: "P3",
    JoyButton.JOY_BUTTON_PADDLE4: "P4",
    JoyButton.JOY_BUTTON_TOUCHPAD: "Touch"
}

func get_joypad_name(button_id: JoyButton) -> String:
    var joypad_type = "xbox"
    
    var joypad_id = Input.get_connected_joypads().get(0)
    if joypad_id:
        var n = Input.get_joy_name(joypad_id).to_lower()
        if n.find("sony") != -1 or n.find("playstation") != -1 or n.find("ps4") != -1 or n.find("ps5") != -1:
            joypad_type = "sony"
        elif n.find("nintendo") != -1 or n.find("switch") != -1:
            joypad_type = "nintendo"
        # Fall back to xbox

    var fallback = FALLBACK_JOY_BUTTON_MAP.get(button_id, "Button%d" % button_id)
    if joypad_type == "sony":
        return SONY_JOY_BUTTON_MAP.get(button_id, fallback)
    elif joypad_type == "nintendo":
        return NINTENDO_JOY_BUTTON_MAP.get(button_id, fallback)
    else:
        return XBOX_JOY_BUTTON_MAP.get(button_id, fallback)

static func customize_keycode(keycode: String) -> String:
    for oldKey in CUSTOM_KEYCODE_REPLACEMENTS.keys():
        keycode = keycode.replace(oldKey, CUSTOM_KEYCODE_REPLACEMENTS[oldKey])
    return keycode

func get_input_properties() -> Dictionary[String, Dictionary]:
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

    var input_property_map: Dictionary[String, Dictionary]
    for pi in input_properties:
        input_property_map[pi["name"].get_slice("/", 1)] = pi

    return input_property_map

func _validate_property(property: Dictionary):
    if property.name == "action":
        var actions = ""
        
        var input_properties = get_input_properties()
        for actionName in input_properties.keys():
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

    Input.joy_connection_changed.connect(update_defaults)
    InputSettingsSingleton.settings_changed.connect(update_defaults)

func update_defaults():
    if !is_node_ready():
        return
    
    visible = (not force_hide) and (InputSettingsSingleton.show_bind_hints or is_necessary)
    if not visible:
        return # No point in updating
    
    var action_property = get_input_properties().get(action)
    if action_property == null:
        $%KeyLabel.text = "ERR"
    else:
        var action_data = ProjectSettings[action_property["name"]]
        var joypads = Input.get_connected_joypads()
        var has_joypad_connected = joypads.size() > 0

        var suitable_event_shortnames = action_data["events"].filter(func(ev: Variant):
            if ev is InputEventKey:
                return !has_joypad_connected
            elif ev is InputEventJoypadButton:
                return has_joypad_connected
            else:
                return false
        ).map(func(ev: InputEvent):
            if ev is InputEventKey:
                var keystr = OS.get_keycode_string((ev as InputEventKey).get_keycode_with_modifiers())
                keystr += OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(ev.physical_keycode))
                return customize_keycode(keystr)
            elif ev is InputEventJoypadButton:
                return get_joypad_name((ev as InputEventJoypadButton).button_index)
            else:
                return "idk"
        )

        if len(suitable_event_shortnames) == 0:
            $%KeyLabel.text = "NONE"
        else:
            $%KeyLabel.text = suitable_event_shortnames[0]
    
    $%InfoText.text = placeholderText
    $%TimedInteractProgress.visible = false
    
    $%Layout.layout_direction = direction

func update(interact_action: InteractionAction):
    if interact_action == null:
        visible = false
        progress.visible = false
        return
    
    visible = true
    
    var nameText = interact_action.name
    if interact_action.time_required > 0.0:
        nameText += " (%.1fs)" % (interact_action.time_required - interact_action.current_time)
    infoText.text = nameText
    
    if interact_action.time_required > 0.0:
        progress.visible = true
        progress.value = ease(interact_action.current_time / interact_action.time_required, -1.2)
    else:
        progress.visible = false
