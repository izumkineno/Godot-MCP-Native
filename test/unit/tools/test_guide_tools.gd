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

func test_register_tools_adds_project_guide_tool():
	var server_core: RefCounted = load("res://addons/godot_mcp/native_mcp/mcp_server_core.gd").new()
	_guide_tools.register_tools(server_core)
	assert_true(server_core.has_tool("project_guide"), "Project guide should be registered")

func test_guide_tool_overview_includes_short_paths_for_all_entry_sections():
	var result: Dictionary = _guide_tools._tool_mcp_start_here({})
	assert_true(result.has("topic"), "Guide tool result should include topic")
	assert_eq(result["topic"], "overview", "Default topic should be overview")
	assert_eq(result.get("recommended_section", ""), "overview", "Overview should recommend the overview route")
	assert_true(result.has("next_steps"), "Guide tool result should include next steps")
	assert_true(result.has("sections"), "Guide tool result should include sections")
	var sections: Array = result["sections"]
	assert_eq(sections.size(), 7, "Guide tool should return all high-frequency entry sections")
	var section_names: Array = []
	for section in sections:
		section_names.append(section.get("name", ""))
	assert_true("development" in section_names, "Guide tool should include development guidance")
	assert_true("debugging" in section_names, "Guide tool should include debugging guidance")
	assert_true("runtime" in section_names, "Guide tool should include runtime guidance")
	assert_true("health" in section_names, "Guide tool should include health guidance")
	assert_true("scene" in section_names, "Guide tool should include scene guidance")
	assert_true("node" in section_names, "Guide tool should include node guidance")
	assert_true("script" in section_names, "Guide tool should include script guidance")
	assert_true(str(result.get("summary", "")).contains("Start here before using any other tool"), "Overview summary should explain the first-read guide")
	assert_true(str(result.get("next_steps", [])[0]).contains("Read the overview first"), "Overview should tell agents to read the guide first")
	var next_steps: Array = result.get("next_steps", [])
	var run_project_index: int = -1
	var sessions_index: int = -1
	var threads_index: int = -1
	var stacks_index: int = -1
	for i in range(next_steps.size()):
		var step: String = str(next_steps[i])
		if run_project_index == -1 and step.contains("run_project"):
			run_project_index = i
		if sessions_index == -1 and step.contains("get_debugger_sessions"):
			sessions_index = i
		if threads_index == -1 and step.contains("get_debug_threads"):
			threads_index = i
		if stacks_index == -1 and step.contains("get_debug_stack_frames"):
			stacks_index = i
	assert_true(run_project_index != -1, "Overview should mention run_project")
	assert_true(sessions_index != -1, "Overview should mention get_debugger_sessions")
	assert_true(threads_index != -1, "Overview should mention get_debug_threads")
	assert_true(stacks_index != -1, "Overview should mention get_debug_stack_frames")
	assert_true(run_project_index < sessions_index, "run_project should come before debugger session inspection")
	assert_true(sessions_index < threads_index, "Debugger sessions should come before debug threads")
	assert_true(threads_index < stacks_index, "Debug threads should come before stack frames")
	assert_true(str(result.get("summary", "")).contains("debug stacks"), "Overview summary should mention debug stacks as the main evidence")

func test_guide_tool_topic_filters_sections():
	var result: Dictionary = _guide_tools._tool_mcp_start_here({"topic": "debugging"})
	assert_eq(result.get("topic", ""), "debugging", "Topic should echo debugging")
	var sections: Array = result.get("sections", [])
	assert_eq(sections.size(), 1, "Topic filter should return one section")
	assert_eq(sections[0].get("name", ""), "debugging", "Filtered section should be debugging")
	assert_eq(result.get("recommended_section", ""), "debugging", "Filtered topic should recommend itself")

func test_guide_tool_topic_filters_scene_section():
	var result: Dictionary = _guide_tools._tool_mcp_start_here({"topic": "scene"})
	assert_eq(result.get("topic", ""), "scene", "Topic should echo scene")
	var sections: Array = result.get("sections", [])
	assert_eq(sections.size(), 1, "Topic filter should return one scene section")
	assert_eq(sections[0].get("name", ""), "scene", "Filtered section should be scene")
	assert_eq(result.get("recommended_section", ""), "scene", "Filtered topic should recommend itself")

func test_guide_tool_topic_filters_node_section():
	var result: Dictionary = _guide_tools._tool_mcp_start_here({"topic": "node"})
	assert_eq(result.get("topic", ""), "node", "Topic should echo node")
	var sections: Array = result.get("sections", [])
	assert_eq(sections.size(), 1, "Topic filter should return one node section")
	assert_eq(sections[0].get("name", ""), "node", "Filtered section should be node")
	assert_eq(result.get("recommended_section", ""), "node", "Filtered topic should recommend itself")

func test_guide_tool_topic_filters_script_section():
	var result: Dictionary = _guide_tools._tool_mcp_start_here({"topic": "script"})
	assert_eq(result.get("topic", ""), "script", "Topic should echo script")
	var sections: Array = result.get("sections", [])
	assert_eq(sections.size(), 1, "Topic filter should return one script section")
	assert_eq(sections[0].get("name", ""), "script", "Filtered section should be script")
	assert_eq(result.get("recommended_section", ""), "script", "Filtered topic should recommend itself")

func test_guide_tool_task_infers_debugging():
	var result: Dictionary = _guide_tools._tool_mcp_start_here({"task": "The game crashes when I step through the debugger"})
	assert_eq(result.get("topic", ""), "debugging", "Crash/debug tasks should route to debugging")
	assert_eq(result.get("recommended_section", ""), "debugging", "Debug task should recommend debugging")
	assert_eq(result.get("task_echo", ""), "The game crashes when I step through the debugger", "Task echo should preserve the original input")

func test_guide_tool_task_infers_scene():
	var result: Dictionary = _guide_tools._tool_mcp_start_here({"task": "I need to inspect the current scene tree before editing"})
	assert_eq(result.get("topic", ""), "scene", "Scene tasks should route to scene")
	assert_eq(result.get("recommended_section", ""), "scene", "Scene task should recommend scene")

func test_guide_tool_task_infers_node():
	var result: Dictionary = _guide_tools._tool_mcp_start_here({"task": "I need to create a node and update its properties"})
	assert_eq(result.get("topic", ""), "node", "Node tasks should route to node")
	assert_eq(result.get("recommended_section", ""), "node", "Node task should recommend node")

func test_guide_tool_task_infers_script():
	var result: Dictionary = _guide_tools._tool_mcp_start_here({"task": "I need to read a script, modify it, and validate the result"})
	assert_eq(result.get("topic", ""), "script", "Script tasks should route to script")
	assert_eq(result.get("recommended_section", ""), "script", "Script task should recommend script")

func test_guide_tool_unknown_topic_returns_error():
	var result: Dictionary = _guide_tools._tool_mcp_start_here({"topic": "unknown"})
	assert_true(result.has("error"), "Unknown topic should return an error")

func test_guide_tool_group_route_returns_group_guide():
	var result: Dictionary = _guide_tools._tool_mcp_start_here({"group": "debug"})
	assert_eq(result.get("topic", ""), "group_guide", "Group routing should return group guide topic")
	assert_eq(result.get("recommended_section", ""), "debug", "Group routing should echo the requested group")
	assert_true(result.has("group_guide"), "Group routing should include a nested group guide")
	assert_true(str(result.get("summary", "")).contains("Debug & Runtime tools"), "Group summary should describe the requested group")

func test_editor_advanced_group_includes_execute_editor_script():
	var definitions: Array = _guide_tools._get_group_definitions()
	var found_group: bool = false
	for definition in definitions:
		if definition.get("name", "") != "editor":
			continue
		for subgroup in definition.get("subgroups", []):
			if subgroup.get("name", "") != "Editor-Advanced":
				continue
			found_group = true
			var tools: Array = subgroup.get("tools", [])
			assert_true("execute_editor_script" in tools, "Editor-Advanced should include execute_editor_script")
			assert_eq(tools.count("execute_editor_script"), 1, "execute_editor_script should appear only once")
			break
	assert_true(found_group, "Editor group should expose Editor-Advanced subgroup")
