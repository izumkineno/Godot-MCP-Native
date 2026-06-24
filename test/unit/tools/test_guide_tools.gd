extends "res://addons/gut/test.gd"

var _guide_tools: RefCounted = null

func before_each():
	_guide_tools = load("res://addons/godot_mcp/tools/guide_tools_native.gd").new()

func after_each():
	_guide_tools = null

func test_register_tools_exists():
	assert_ne(_guide_tools, null, "Guide tools should load successfully")
	assert_true(_guide_tools.has_method("register_tools"), "Guide tools should expose register_tools")

func test_register_tools_adds_guide_tool():
	var server_core: RefCounted = load("res://addons/godot_mcp/native_mcp/mcp_server_core.gd").new()
	_guide_tools.register_tools(server_core)
	assert_true(server_core.has_tool("mcp_start_here"), "Guide tool should be registered")

func test_guide_tool_overview_contains_tool_selection_and_debug_sections():
	var result: Dictionary = _guide_tools._tool_mcp_start_here({})
	assert_true(result.has("topic"), "Guide tool result should include topic")
	assert_eq(result["topic"], "overview", "Default topic should be overview")
	assert_eq(result.get("recommended_section", ""), "overview", "Overview should recommend the overview route")
	assert_true(result.has("sections"), "Guide tool result should include sections")
	var sections: Array = result["sections"]
	assert_true(sections.size() >= 4, "Guide tool should return multiple guide sections")
	var section_names: Array = []
	for section in sections:
		section_names.append(section.get("name", ""))
	assert_true("development" in section_names, "Guide tool should include development guidance")
	assert_true("debugging" in section_names, "Guide tool should include debugging guidance")
	assert_true("runtime" in section_names, "Guide tool should include runtime guidance")
	assert_true("health" in section_names, "Guide tool should include health guidance")
	assert_true(str(result.get("summary", "")).contains("development tools"), "Overview summary should explain the development route")

func test_guide_tool_topic_filters_sections():
	var result: Dictionary = _guide_tools._tool_mcp_start_here({"topic": "debugging"})
	assert_eq(result.get("topic", ""), "debugging", "Topic should echo debugging")
	var sections: Array = result.get("sections", [])
	assert_eq(sections.size(), 1, "Topic filter should return one section")
	assert_eq(sections[0].get("name", ""), "debugging", "Filtered section should be debugging")
	assert_eq(result.get("recommended_section", ""), "debugging", "Filtered topic should recommend itself")

func test_guide_tool_task_infers_debugging():
	var result: Dictionary = _guide_tools._tool_mcp_start_here({"task": "The game crashes when I step through the debugger"})
	assert_eq(result.get("topic", ""), "debugging", "Crash/debug tasks should route to debugging")
	assert_eq(result.get("recommended_section", ""), "debugging", "Debug task should recommend debugging")
	assert_eq(result.get("task_echo", ""), "The game crashes when I step through the debugger", "Task echo should preserve the original input")

func test_guide_tool_unknown_topic_returns_error():
	var result: Dictionary = _guide_tools._tool_mcp_start_here({"topic": "unknown"})
	assert_true(result.has("error"), "Unknown topic should return an error")
