extends Resource

class_name ConstructableData

@export var id: StringName

@export var name: String
@export_multiline var description: String

@export var texture: Texture2D

func can_construct(idk: Variant):
    print(idk)
