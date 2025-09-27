@tool

extends Node2D

@export var facing: String:
    set(val):
        facing = val
        _update_sprite()

@export var meaning: StringName:
    set(val):
        meaning = val
        _update_sprite()

@export var shown: bool = true:
    set(val):
        if val != shown:
            var t = create_tween()
            if shown:
                t.tween_property(self, "modulate:a", 1.0, 0.2)
            else:
                t.tween_property(self, "modulate:a", 0, 0.2)
        shown = val

@onready var sprite: Sprite2D = $AutomationObjectSprite

const AUTOMATION_OBJECTS_TILESET: TileSet = preload("res://scripts/automation/automationObjectsTileset.tres")

class AutomationObjectTileDataDirection:
    var color: Color
    var texture: Texture2D

    @warning_ignore("shadowed_variable")
    func _init(color: Color, texture: Texture):
        self.color = color
        self.texture = texture
    
    func _to_string():
        return "Dir(color=%s)" % color

class AutomationObjectTileData:
    var meaning: StringName

    var directions: Dictionary[String, AutomationObjectTileDataDirection]

    @warning_ignore("shadowed_variable")
    func _init(meaning: StringName):
        self.meaning = meaning
    
    func add(direction: String, data: AutomationObjectTileDataDirection):
        directions.set(direction, data)
    
    func get_dir(direction: String) -> AutomationObjectTileDataDirection:
        return directions.get(direction, null)
    
    func _to_string():
        return "TileData(meaning=%s, directions=%s)" % [meaning, directions]

var automation_object_tiles: Dictionary[StringName, AutomationObjectTileData] = {}

func _ready():
    var source_id = 0
    var source: TileSetAtlasSource = AUTOMATION_OBJECTS_TILESET.get_source(source_id)

    for tile_idx in range(source.get_tiles_count()):
        var pos = source.get_tile_id(tile_idx)
        for alt_idx in range(source.get_alternative_tiles_count(pos)):
            var alt_id = source.get_alternative_tile_id(pos, alt_idx)

            var tile_data = source.get_tile_data(pos, alt_id)
            var tile_meaning = tile_data.get_custom_data("meaning")

            if !automation_object_tiles.has(tile_meaning):
                automation_object_tiles[tile_meaning] = AutomationObjectTileData.new(tile_meaning)

            var tile_facing = tile_data.get_custom_data("facing")

            var region = source.get_tile_texture_region(pos, 0)
            var image = source.texture.get_image().get_region(region)
            var texture = ImageTexture.create_from_image(image)

            automation_object_tiles[tile_meaning].add(tile_facing, AutomationObjectTileDataDirection.new(
                tile_data.modulate,
                texture
            ))
    
    _update_sprite()

func _update_sprite():
    if sprite == null:
        return
    
    var tile_data = automation_object_tiles.get(meaning, null)
    if tile_data == null:
        sprite.texture = null
        return
    
    var dir_data = tile_data.get_dir(facing)
    if dir_data == null:
        sprite.texture = null
        return
    
    sprite.texture = dir_data.texture
    sprite.modulate = dir_data.color
