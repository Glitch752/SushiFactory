extends Resource

class_name MachineData

@export var id: StringName
@export var machine_name: String:
    get:
        return tr(machine_name)

## If this machine causes a custom counter tile beneath it, this is the X position in the atlas of that counter.
@export var custom_counter_x: int = -1