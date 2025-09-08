extends TileMapLayer

func _tile_data_runtime_update(_coords: Vector2i, tile_data: TileData):
    if tile_data.get_custom_data("automation_placeable"):
        tile_data.modulate.a = 0.0

func _use_tile_data_runtime_update(_coords: Vector2i):
    return true

func _ready():
    notify_runtime_tile_data_update()
