class_name MCPSettingsManager
extends "res://addons/godot_mcp/native_mcp/config_manager.gd"

const CONFIG_FILE_NAME: String = "mcp_settings.cfg"
const SECTION_SETTINGS: String = "settings"
const PLUGIN_CONFIG_PATH: String = "res://addons/godot_mcp/plugin.cfg"
const PLUGIN_CONFIG_SECTION: String = "mcp"

const DEFAULT_SETTINGS: Dictionary = {
	"transport_mode": "http",
	"http_port": 9080,
	"auth_enabled": false,
	"auth_token": "",
	"sse_enabled": true,
	"allow_remote": false,
	"cors_origin": "*",
	"auto_start": false,
	"log_level": 2,
	"security_level": 1,
	"rate_limit": 100,
	"language": "en"
}

func _init() -> void:
	config_file_name = CONFIG_FILE_NAME
	config_section = SECTION_SETTINGS
	storage_version = 1

func load_settings() -> Dictionary:
	var saved: Dictionary = load_config()
	var merged: Dictionary = _build_default_settings()
	for key in saved:
		if merged.has(key):
			merged[key] = saved[key]
	return merged

func _build_default_settings() -> Dictionary:
	var defaults: Dictionary = DEFAULT_SETTINGS.duplicate(true)
	var plugin_config: ConfigFile = ConfigFile.new()
	if plugin_config.load(PLUGIN_CONFIG_PATH) != OK:
		return defaults
	if not plugin_config.has_section(PLUGIN_CONFIG_SECTION):
		return defaults
	for key in defaults.keys():
		if plugin_config.has_section_key(PLUGIN_CONFIG_SECTION, key):
			defaults[key] = plugin_config.get_value(PLUGIN_CONFIG_SECTION, key)
	return defaults

func save_settings(settings: Dictionary) -> bool:
	return save_config(settings)