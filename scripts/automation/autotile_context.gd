class_name AutotileContext

var cell: Vector2i
var cell_data: TileData
var interactable: Node2D

## func(cell: Vector2i) -> TileData
var _get_cell_tile_data: Callable
## func(cell: Vector2i, source_id: int = -1, atlas_coords: Vector2i = Vector2i(-1, -1), alternative_tile: int = 0)
var _set_cell: Callable
## func(cell: Vector2i, source_id: int = -1, atlas_coords: Vector2i = Vector2i(-1, -1), alternative_tile: int = 0)
var _set_underlayer_cell: Callable

## Wrapper for proper typing. Yay GDScript.
func set_cell(coords: Vector2i, source_id: int = -1, atlas_coords: Vector2i = Vector2i(-1, -1), alternative_tile: int = 0):
    _set_cell.call(coords, source_id, atlas_coords, alternative_tile)

func set_underlayer_cell(coords: Vector2i, source_id: int = -1, atlas_coords: Vector2i = Vector2i(-1, -1), alternative_tile: int = 0):
    _set_underlayer_cell.call(coords, source_id, atlas_coords, alternative_tile)

## Wrapper for proper typing. Yay GDScript.
func get_cell_tile_data(coords: Vector2i) -> TileData:
    return _get_cell_tile_data.call(coords)