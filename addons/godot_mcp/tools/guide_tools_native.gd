@tool
class_name GuideToolsNative
extends RefCounted

func initialize(editor_interface: EditorInterface) -> void:
	pass

func register_tools(server_core: RefCounted) -> void:
	_register_mcp_start_here(server_core)

func _register_mcp_start_here(server_core: RefCounted) -> void:
	var tool_name: String = "mcp_start_here"
	var description: String = "Read first guide for selecting development, debugging, runtime helpers, and project health checks."
	var input_schema: Dictionary = {
		"type": "object",
		"properties": {
			"topic": {
				"type": "string",
				"enum": ["overview", "development", "debugging", "runtime", "health"],
				"description": "Optional section to return. Use overview, development, debugging, runtime, or health."
			},
			"task": {
				"type": "string",
				"description": "Optional natural-language task or symptom. When provided, the guide infers the best-fit section."
			}
		}
	}
	var output_schema: Dictionary = {
		"type": "object",
		"properties": {
			"topic": {"type": "string"},
			"recommended_section": {"type": "string"},
			"task_echo": {"type": "string"},
			"sections": {"type": "array"},
			"summary": {"type": "string"}
		}
	}
	var annotations: Dictionary = {
		"readOnlyHint": true,
		"destructiveHint": false,
		"idempotentHint": true,
		"openWorldHint": false
	}

	server_core.register_tool(
		tool_name,
		description,
		input_schema,
		Callable(self, "_tool_mcp_start_here"),
		output_schema,
		annotations,
		"supplementary",
		"Guide",
		-100,
		true
	)

func _tool_mcp_start_here(params: Dictionary) -> Dictionary:
	var topic_input: String = str(params.get("topic", "")).strip_edges()
	var task: String = str(params.get("task", "")).strip_edges()
	var topic: String = topic_input
	if topic.is_empty():
		topic = _infer_topic_from_task(task) if not task.is_empty() else "overview"
	var sections: Array[Dictionary] = _build_sections()
	var filtered_sections: Array[Dictionary] = []
	var recommended_section: String = topic

	sections.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("priority", 0)) < int(b.get("priority", 0))
	)

	if topic == "overview":
		filtered_sections = sections
	else:
		for section in sections:
			if section.get("name", "") == topic:
				filtered_sections.append(section)
		if filtered_sections.is_empty():
			return {"error": "Unknown topic: " + topic}

	if not task.is_empty() and topic == "overview":
		recommended_section = _infer_topic_from_task(task)

	return {
		"topic": topic,
		"recommended_section": recommended_section,
		"task_echo": task,
		"summary": _build_summary(topic, filtered_sections, recommended_section, task),
		"sections": filtered_sections
	}

func _build_sections() -> Array[Dictionary]:
	return [
		{
			"name": "development",
			"title": "Function development",
			"priority": 1,
			"when_to_read": "Use this first when you are planning a feature or changing behavior.",
			"recommended_tools": [
				"get_editor_state",
				"get_current_scene",
				"get_current_script",
				"list_nodes",
				"get_node_properties",
				"read_script",
				"list_project_scripts",
				"search_in_files",
				"get_project_info",
				"get_project_settings"
			],
			"selection_rule": "Start with the smallest read-only tool that tells you where the change belongs, then move to the specific write tool."
		},
		{
			"name": "debugging",
			"title": "Debug workflow",
			"priority": 2,
			"when_to_read": "Use this when something behaves incorrectly and you need to inspect runtime state.",
			"recommended_tools": [
				"get_editor_logs",
				"run_project",
				"get_debugger_sessions",
				"install_runtime_probe",
				"get_debug_stack_frames",
				"get_debug_stack_variables",
				"get_debug_variables",
				"get_debug_output",
				"await_debugger_state",
				"debug_continue_and_wait",
				"debug_step_over_and_wait"
			],
			"selection_rule": "Confirm the current runtime state before stepping or mutating anything."
		},
		{
			"name": "runtime",
			"title": "Runtime helpers",
			"priority": 3,
			"when_to_read": "Use this when you need runtime animation, audio, shader, tilemap, or screenshot tooling.",
			"recommended_tools": [
				"get_runtime_info",
				"get_runtime_screenshot",
				"list_runtime_animations",
				"play_runtime_animation",
				"get_runtime_shader_parameters",
				"set_runtime_shader_parameter",
				"list_runtime_audio_buses",
				"update_runtime_audio_bus",
				"list_runtime_tilemap_layers",
				"set_runtime_tilemap_cell"
			],
			"selection_rule": "Use runtime helpers after you have confirmed the project is in the right state."
		},
		{
			"name": "health",
			"title": "Project health checks",
			"priority": 4,
			"when_to_read": "Use this when the project may have broken scripts, missing resources, or import issues.",
			"recommended_tools": [
				"audit_project_health",
				"detect_broken_scripts",
				"scan_missing_resource_dependencies",
				"scan_cyclic_resource_dependencies",
				"fix_resource_uid",
				"get_resource_uid_info",
				"get_import_metadata",
				"reimport_resources"
			],
			"selection_rule": "Run the lightest diagnostic that can confirm the suspected problem before deeper scans."
		}
	]

func _build_summary(topic: String, sections: Array[Dictionary], recommended_section: String, task: String) -> String:
	if topic == "overview":
		var base_summary: String = "Use this first to route feature work to development tools, runtime failures to debugging tools, play-mode helpers to runtime tools, and broken imports or scripts to health tools."
		if not task.is_empty():
			return base_summary + " Suggested section: " + recommended_section + "."
		return base_summary
	for section in sections:
		if section.get("name", "") == topic:
			var selection_rule: String = str(section.get("selection_rule", ""))
			var title: String = str(section.get("title", topic))
			return title + ": " + selection_rule
	return ""

func _infer_topic_from_task(task: String) -> String:
	var normalized: String = task.to_lower()
	if normalized.is_empty():
		return "overview"
	if _contains_any(normalized, ["debug", "error", "crash", "log", "stack", "breakpoint", "trace", "exception", "pause"]):
		return "debugging"
	if _contains_any(normalized, ["run", "play", "runtime", "animation", "audio", "shader", "tilemap", "screenshot", "input"]):
		return "runtime"
	if _contains_any(normalized, ["health", "broken", "missing", "dependency", "uid", "import", "reimport", "audit"]):
		return "health"
	if _contains_any(normalized, ["scene", "node", "script", "tool", "feature", "edit", "modify", "create", "refactor", "build"]):
		return "development"
	return "development"

func _contains_any(text: String, terms: Array[String]) -> bool:
	for term in terms:
		if text.find(term) >= 0:
			return true
	return false
