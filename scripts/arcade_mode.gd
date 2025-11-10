extends Node

const FORCE_ARCADE = true

func is_arcade_mode() -> bool:
    return OS.has_feature("arcade") or FORCE_ARCADE
