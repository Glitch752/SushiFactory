@tool
extends EditorPlugin

var parser_plugin: EditorTranslationParserPlugin

func _enter_tree():
    parser_plugin = load("res://addons/resource_translation/parser_plugin.gd").new()
    add_translation_parser_plugin(parser_plugin)


func _exit_tree():
    remove_translation_parser_plugin(parser_plugin)
