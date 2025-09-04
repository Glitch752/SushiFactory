extends TileMapLayer

@onready var player = $"../PlayerCharacter"
@onready var objectsTileMap: TileMapLayer = $"."

func _ready():
    $InteractionHint.visible = false
    add_user_signal("structure_interacted")

func _unhandled_input(event):
    if event.is_action_pressed("interact"):
        var cell = get_interacting_tile()
        if cell:
            objectsTileMap.emit_signal("structure_interacted", cell)

func _process(_delta):
    var hint = $InteractionHint
    
    # If the player is directly adjacent to a structure, make an interaction hint above it
    var cell = get_interacting_tile()
    if cell:
        # We found an adjacent structure
        var global_tile_pos = objectsTileMap.to_global(objectsTileMap.map_to_local(cell))
        #var offset_away_from_player = (global_tile_pos - player.global_position).normalized().snapped(Vector2.ONE) * 24
        hint.global_position = global_tile_pos # + offset_away_from_player
        hint.visible = true
        return
    
    $InteractionHint.visible = false

## Returns: Vector2i | null
func get_interacting_tile() -> Variant:
    #var player_cell = objectsTileMap.local_to_map(objectsTileMap.to_local(player.global_position))
    #var adjacent_cells = objectsTileMap.get_surrounding_cells(player_cell)
    #for cell in adjacent_cells:
        #var tile_id = objectsTileMap.get_cell_source_id(cell)
        #if tile_id != -1:
            #return cell

    var interaction_cell = objectsTileMap.local_to_map(objectsTileMap.to_local(player.interaction_point()))
    var tile_id = objectsTileMap.get_cell_source_id(interaction_cell)
    if tile_id != -1:
        return interaction_cell
    
    return null
