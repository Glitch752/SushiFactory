## ahhh there HAS to be a better way to do this, this is dumb

extends Node

const AUTOMATION_OBJECTS_TILESET: TileSet = preload("res://scripts/automation/automationObjectsTileset.tres")

func _ready():
    var temp_tilemap = TileMapLayer.new()
    
    var source: TileSetSource = AUTOMATION_OBJECTS_TILESET.get_source(0)
    

    for tile_idx in range(source.get_tiles_count()):
        # TODO
        for alt_idx in range(source.get_alternative_tiles_count(pos)):
            temp_tilemap.set_cell(Vector2i(0, 0))