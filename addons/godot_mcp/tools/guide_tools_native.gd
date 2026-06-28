@tool
class_name GuideToolsNative
extends RefCounted

func initialize(editor_interface: EditorInterface) -> void:
	pass

func register_tools(server_core: RefCounted) -> void:
	_register_mcp_start_here(server_core)
	_register_list_groups(server_core)
	_register_group_guide(server_core, "node")
	_register_group_guide(server_core, "scene")
	_register_group_guide(server_core, "script")
	_register_group_guide(server_core, "editor")
	_register_group_guide(server_core, "debug")
	_register_group_guide(server_core, "project")

# ============================================================================
# 分组定义数据（集中维护）
# ============================================================================

static func _get_group_definitions() -> Array[Dictionary]:
	return [
		{
			"name": "guide",
			"title": "Guide tools (this group)",
			"guide_tool": "mcp_start_here",
			"priority": 0,
			"when_to_read": "Always start here. Use mcp_start_here or list_groups to navigate all tool groups.",
			"subgroups": [
				{
					"name": "Guide",
					"tools": ["mcp_start_here", "list_groups", "node_guide", "scene_guide", "script_guide", "editor_guide", "debug_guide", "project_guide"],
					"workflow": "1) mcp_start_here (overview) → 2) mcp_start_here(group=...) or list_groups → 3) Use recommended tools from the chosen group.",
					"rule": "Call mcp_start_here first before any other tool. Use list_groups to discover all available group guides."
				}
			],
			"cross_refs": ["All groups — each has a dedicated guide reachable via mcp_start_here(group=xx)"]
		},
		{
			"name": "node",
			"title": "Node tools",
			"guide_tool": "node_guide",
			"priority": 1,
			"when_to_read": "Use when creating, deleting, modifying nodes, or working with signals and groups.",
			"subgroups": [
				{
					"name": "Node-Write",
					"tools": ["create_node", "delete_node", "update_node_property", "duplicate_node", "move_node", "rename_node", "add_resource", "set_anchor_preset"],
					"workflow": "1) create_node → 2) update_node_property / rename_node / move_node → 3) connect_signal / set_node_groups",
					"rule": "Always call get_scene_structure or list_nodes first to confirm the target path."
				},
				{
					"name": "Node-Advanced",
					"tools": ["batch_update_node_properties", "batch_scene_node_edits", "connect_signal", "disconnect_signal", "get_node_groups", "set_node_groups", "find_nodes_in_group", "audit_scene_node_persistence", "audit_scene_inheritance"],
					"workflow": "Batch tools replace multiple sequential edits; audit tools check scene integrity before making changes.",
					"rule": "Use batch_update_node_properties over chained update_node_property calls when changing ≥2 properties on the same node."
				}
			],
			"cross_refs": ["scene → to switch scenes before editing nodes", "script → to attach scripts to nodes"]
		},
		{
			"name": "scene",
			"title": "Scene tools",
			"guide_tool": "scene_guide",
			"priority": 2,
			"when_to_read": "Use when creating, saving, opening, or listing scenes.",
			"subgroups": [
				{
					"name": "Scene",
					"tools": ["create_scene", "save_scene", "open_scene", "get_current_scene"],
					"workflow": "1) list_project_scenes → 2) open_scene → 3) get_current_scene (verify) → 4) edit nodes → 5) save_scene",
					"rule": "Always call get_current_scene after open_scene to confirm the correct scene loaded. Check is_modified before closing."
				},
				{
					"name": "Scene-Advanced",
					"tools": ["get_scene_structure", "list_project_scenes", "list_open_scenes", "close_scene_tab"],
					"workflow": "list_open_scenes shows all open tabs; close_scene_tab closes the active or a named tab.",
					"rule": "Call list_open_scenes before close_scene_tab to know which tabs are open."
				}
			],
			"cross_refs": ["node → to edit nodes after opening a scene", "script → to attach scripts to scene nodes"]
		},
		{
			"name": "script",
			"title": "Script tools",
			"guide_tool": "script_guide",
			"priority": 3,
			"when_to_read": "Use when reading, creating, modifying, analyzing, or searching scripts.",
			"subgroups": [
				{
					"name": "Script",
					"tools": ["list_project_scripts", "read_script", "create_script", "modify_script", "get_current_script"],
					"workflow": "1) list_project_scripts → 2) read_script → 3) modify_script or create_script → 4) validate_script",
					"rule": "Always read_script before modify_script to know the current content. Always validate_script after modifying."
				},
				{
					"name": "Script-Advanced",
					"tools": ["list_project_script_symbols", "find_script_symbol_definition", "find_script_symbol_references", "rename_script_symbol", "analyze_script", "open_script_at_line", "attach_script", "validate_script", "search_in_files"],
					"workflow": "1) search_in_files or list_project_script_symbols → 2) find_script_symbol_definition → 3) read_script → 4) modify_script",
					"rule": "Use find_script_symbol_references before rename_script_symbol to see all usage sites."
				}
			],
			"cross_refs": ["node → attach_script to bind scripts to nodes", "editor → open_script_at_line to jump to definitions"]
		},
		{
			"name": "editor",
			"title": "Editor tools",
			"guide_tool": "editor_guide",
			"priority": 4,
			"when_to_read": "Use when inspecting editor state, running/stopping the project, managing selection, or exporting.",
			"subgroups": [
				{
					"name": "Editor",
					"tools": ["get_editor_state", "run_project", "stop_project"],
					"workflow": "1) get_editor_state → 2) run_project (or stop_project if already running) → 3) await_scene_ready",
					"rule": "Check get_editor_state first to confirm the editor is in the expected state before running."
				},
				{
					"name": "Editor-Advanced",
					"tools": ["get_selected_nodes", "select_node", "select_file", "get_inspector_properties", "set_editor_setting", "get_editor_screenshot", "get_signals", "reload_project", "list_export_presets", "inspect_export_templates", "validate_export_preset", "run_export"],
					"workflow": "select_node before update_node_property; reload_project after external file changes; execute_editor_script for multi-line GDScript in editor context.",
					"rule": "Use get_inspector_properties to list available properties before calling update_node_property."
				}
			],
			"cross_refs": ["scene → to open/close scenes", "debug → to run and debug the project"]
		},
		{
			"name": "debug",
			"title": "Debug & Runtime tools",
			"guide_tool": "debug_guide",
			"priority": 5,
			"when_to_read": "Use when debugging scripts, inspecting runtime state, manipulating runtime nodes, or testing input. Requires the project to be running.",
			"subgroups": [
				{
					"name": "Debug",
					"tools": ["get_editor_logs", "execute_script", "get_performance_metrics", "debug_print", "clear_output"],
					"workflow": "1) get_editor_logs → 2) run_project → 3) install_runtime_probe → 4) debug/runtime tools",
					"rule": "Always check get_editor_logs(source='editor_panel') for errors after running the project."
				},
				{
					"name": "Debug-Advanced",
					"tools": [
						"get_debugger_sessions", "get_debug_threads", "set_debugger_breakpoint", "send_debugger_message",
						"toggle_debugger_profiler", "get_debugger_messages", "get_debug_state_events", "get_debug_output",
						"add_debugger_capture_prefix", "get_debug_stack_frames", "get_debug_stack_variables",
						"get_debug_scopes", "get_debug_variables", "expand_debug_variable", "evaluate_debug_expression",
						"install_runtime_probe", "remove_runtime_probe", "request_debug_break", "send_debug_command",
						"debug_step_into", "debug_step_over", "debug_step_out", "debug_continue",
						"debug_step_into_and_wait", "debug_step_over_and_wait", "debug_step_out_and_wait",
						"debug_continue_and_wait", "await_debugger_state",
						"get_runtime_info", "await_scene_ready", "get_runtime_performance_snapshot",
						"get_runtime_memory_trend", "get_runtime_scene_tree", "inspect_runtime_node",
						"create_runtime_node", "delete_runtime_node", "update_runtime_node_property",
						"call_runtime_node_method", "evaluate_runtime_expression", "simulate_runtime_input_event",
						"simulate_runtime_input_action", "list_runtime_input_actions", "upsert_runtime_input_action",
						"remove_runtime_input_action", "list_runtime_animations", "play_runtime_animation",
						"stop_runtime_animation", "get_runtime_animation_state", "get_runtime_animation_tree_state",
						"set_runtime_animation_tree_active", "travel_runtime_animation_tree",
						"get_runtime_material_state", "get_runtime_theme_item", "set_runtime_theme_override",
						"clear_runtime_theme_override", "get_runtime_shader_parameters", "set_runtime_shader_parameter",
						"list_runtime_tilemap_layers", "get_runtime_tilemap_cell", "set_runtime_tilemap_cell",
						"list_runtime_audio_buses", "get_runtime_audio_bus", "update_runtime_audio_bus",
						"get_runtime_screenshot", "await_runtime_condition", "assert_runtime_condition"
					],
					"workflow": "Debug: set_debugger_breakpoint → request_debug_break → get_debug_stack_frames → get_debug_stack_variables → debug_step_over / debug_continue. Runtime: install_runtime_probe → get_runtime_scene_tree → inspect_runtime_node → update_runtime_node_property.",
					"rule": "Confirm the project is running (get_debugger_sessions) before using any runtime tool. Use _and_wait variants after step/continue for synchronous debugging."
				}
			],
			"cross_refs": ["editor → run_project to launch, stop_project to exit", "project → get_project_settings for input actions"]
		},
		{
			"name": "project",
			"title": "Project tools",
			"guide_tool": "project_guide",
			"priority": 6,
			"when_to_read": "Use when inspecting project configuration, InputMap, autoloads, global classes, resources, or running health checks.",
			"subgroups": [
				{
					"name": "Project",
					"tools": ["get_project_info", "get_project_settings"],
					"workflow": "Start with get_project_info to learn the project name/version, then get_project_settings for detail.",
					"rule": "Filter get_project_settings by prefix (e.g. 'input/', 'display/') when looking for specific settings."
				},
				{
					"name": "Project-Advanced",
					"tools": [
						"list_project_tests", "run_project_test", "run_project_tests",
						"list_project_input_actions", "upsert_project_input_action", "remove_project_input_action",
						"list_project_autoloads", "list_project_global_classes", "get_class_api_metadata",
						"inspect_csharp_project_support", "compare_render_screenshots", "inspect_tileset_resource",
						"list_project_resources", "create_resource",
						"get_project_structure", "reimport_resources", "get_import_metadata",
						"get_resource_uid_info", "fix_resource_uid", "get_resource_dependencies",
						"scan_missing_resource_dependencies", "scan_cyclic_resource_dependencies",
						"detect_broken_scripts", "audit_project_health"
					],
					"workflow": "Health: audit_project_health → detect_broken_scripts → scan_missing_resource_dependencies → scan_cyclic_resource_dependencies. Resources: list_project_resources → get_resource_dependencies → fix_resource_uid. Input: list_project_input_actions → upsert_project_input_action.",
					"rule": "Run audit_project_health first when troubleshooting project-wide issues — it covers scripts, resources, and dependencies in one pass."
				}
			],
			"cross_refs": ["debug → get_editor_logs after health checks", "editor → reload_project after fixing resource issues"]
		}
	]

# ============================================================================
# list_groups — 列出所有工具分组及其引导工具
# ============================================================================

func _register_list_groups(server_core: RefCounted) -> void:
	var tool_name: String = "list_groups"
	var description: String = "List all tool groups and their guide tools. Call the guide tool (e.g. node_guide) before using tools in that group."
	var input_schema: Dictionary = {
		"type": "object",
		"properties": {
			"filter": {
				"type": "string",
				"description": "Optional group name filter (e.g. 'node', 'script'). Returns all groups if omitted."
			}
		}
	}
	var output_schema: Dictionary = {
		"type": "object",
		"properties": {
			"groups": {"type": "array"},
			"count": {"type": "integer"},
			"filter": {"type": "string"},
			"summary": {"type": "string"}
		}
	}
	var annotations: Dictionary = {
		"readOnlyHint": true, "destructiveHint": false, "idempotentHint": true, "openWorldHint": false
	}
	server_core.register_tool(
		tool_name, description, input_schema,
		Callable(self, "_tool_list_groups"),
		output_schema, annotations,
		"supplementary", "Guide", -99, true
	)

func _tool_list_groups(params: Dictionary) -> Dictionary:
	var filter: String = str(params.get("filter", "")).strip_edges().to_lower()
	var all_groups: Array[Dictionary] = _get_group_definitions()
	var result: Array = []
	for g in all_groups:
		if not filter.is_empty() and not str(g.get("name", "")).contains(filter):
			continue
		result.append({
			"name": g.get("name", ""),
			"title": g.get("title", ""),
			"guide_tool": g.get("guide_tool", ""),
			"when_to_read": g.get("when_to_read", ""),
			"subgroup_count": g.get("subgroups", []).size()
		})
	return {
		"groups": result,
		"count": result.size(),
		"filter": filter,
		"summary": "Call the guide_tool for a group before using its tools. E.g. call node_guide before create_node."
	}

# ============================================================================
# 分组引导工具（通用注册 + 处理方法）
# ============================================================================

func _register_group_guide(server_core: RefCounted, group_name: String) -> void:
	var defs: Array[Dictionary] = _get_group_definitions()
	var group_def: Dictionary = {}
	for g in defs:
		if g.get("name", "") == group_name:
			group_def = g
			break
	if group_def.is_empty():
		return

	var tool_name: String = str(group_def.get("guide_tool", group_name + "_guide"))
	var description: String = str(group_def.get("title", "")) + " guide. " + str(group_def.get("when_to_read", ""))
	var input_schema: Dictionary = {
		"type": "object",
		"properties": {
			"subgroup": {
				"type": "string",
				"description": "Optional subgroup filter (e.g. 'Node-Write', 'Script-Advanced'). Returns all subgroups if omitted."
			}
		}
	}
	var output_schema: Dictionary = {
		"type": "object",
		"properties": {
			"group": {"type": "string"},
			"title": {"type": "string"},
			"subgroups": {"type": "array"},
			"cross_refs": {"type": "array"},
			"summary": {"type": "string"},
			"next_steps": {"type": "array"}
		}
	}
	var annotations: Dictionary = {
		"readOnlyHint": true, "destructiveHint": false, "idempotentHint": true, "openWorldHint": false
	}
	server_core.register_tool(
		tool_name, description, input_schema,
		Callable(self, "_tool_group_guide").bind(group_def),
		output_schema, annotations,
		"supplementary", "Guide", -90, true
	)

func _tool_group_guide(params: Dictionary, group_def: Dictionary) -> Dictionary:
	var subgroup_filter: String = str(params.get("subgroup", "")).strip_edges()
	var all_subgroups: Array = group_def.get("subgroups", [])
	var filtered_subgroups: Array = []

	for sg in all_subgroups:
		if not subgroup_filter.is_empty():
			var sg_name: String = str(sg.get("name", "")).to_lower()
			if not sg_name.contains(subgroup_filter.to_lower()):
				continue
		filtered_subgroups.append(sg)

	var total_tools: int = 0
	for sg in filtered_subgroups:
		total_tools += sg.get("tools", []).size()

	var next_steps: Array[String] = []
	next_steps.append("Call the first recommended tool for your task.")
	next_steps.append("Return to this guide if the task changes.")
	# Add first tool suggestion
	for sg in filtered_subgroups:
		var tools: Array = sg.get("tools", [])
		if tools.size() > 0:
			next_steps.append("Start with: " + str(tools[0]))

	var cross_refs: Array = group_def.get("cross_refs", [])
	var cross_ref_texts: Array[String] = []
	for ref in cross_refs:
		cross_ref_texts.append(str(ref))

	return {
		"group": group_def.get("name", ""),
		"title": group_def.get("title", ""),
		"subgroups": filtered_subgroups,
		"cross_refs": cross_ref_texts,
		"summary": str(group_def.get("when_to_read", "")) + " Total tools: " + str(total_tools) + ".",
		"next_steps": next_steps
	}

# ============================================================================
# mcp_start_here（增强版，新增 group 参数）
# ============================================================================

func _register_mcp_start_here(server_core: RefCounted) -> void:
	var tool_name: String = "mcp_start_here"
	var description: String = "Read first guide for selecting development, debugging, runtime helpers, and project health checks. Use 'list_groups' for per-group guides."
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
			},
			"group": {
				"type": "string",
				"description": "Optional group name for per-group guide (node, scene, script, editor, debug, project). Overrides topic/task."
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
			"summary": {"type": "string"},
			"next_steps": {"type": "array"},
			"group_guide": {"type": "object"}
		}
	}
	var annotations: Dictionary = {
		"readOnlyHint": true, "destructiveHint": false, "idempotentHint": true, "openWorldHint": false
	}

	server_core.register_tool(
		tool_name, description, input_schema,
		Callable(self, "_tool_mcp_start_here"),
		output_schema, annotations,
		"supplementary", "Guide", -100, true
	)

func _tool_mcp_start_here(params: Dictionary) -> Dictionary:
	# 如果指定了 group，直接返回该组的引导
	var group_param: String = str(params.get("group", "")).strip_edges().to_lower()
	if not group_param.is_empty():
		var defs: Array[Dictionary] = _get_group_definitions()
		for g in defs:
			if str(g.get("name", "")).to_lower() == group_param:
				var guide_result: Dictionary = _tool_group_guide({}, g)
				return {
					"topic": "group_guide",
					"recommended_section": group_param,
					"task_echo": str(params.get("task", "")),
					"sections": [],
					"summary": "Group guide: " + str(g.get("title", "")) + ". " + str(g.get("when_to_read", "")),
					"next_steps": ["Call list_groups to see all available groups.", "Use " + str(g.get("guide_tool", "")) + " for detailed subgroup guidance."],
					"group_guide": guide_result
				}
		return {"error": "Unknown group: " + group_param + ". Use list_groups to see available groups."}

	# 原有逻辑
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
		"next_steps": _build_next_steps(topic, filtered_sections, recommended_section),
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
		var base_summary: String = "Start here before using any other tool. Use this first to route feature work to development tools, runtime failures to debugging tools, play-mode helpers to runtime tools, and broken imports or scripts to health tools."
		if not task.is_empty():
			return base_summary + " Suggested section: " + recommended_section + "."
		return base_summary
	for section in sections:
		if section.get("name", "") == topic:
			var selection_rule: String = str(section.get("selection_rule", ""))
			var title: String = str(section.get("title", topic))
			return title + ": " + selection_rule
	return ""

func _build_next_steps(topic: String, sections: Array[Dictionary], recommended_section: String) -> Array[String]:
	var next_steps: Array[String] = []
	if topic == "overview":
		next_steps.append("Read the overview first.")
		next_steps.append("Pick the recommended section before calling a specialized tool.")
		next_steps.append("For per-group guidance, call list_groups or use mcp_start_here with group= parameter.")
		for section in sections:
			var section_name: String = str(section.get("name", ""))
			if not section_name.is_empty():
				next_steps.append("Use " + section_name + " tools only after confirming the task fits that section.")
		return next_steps
	next_steps.append("Use the " + topic + " section for this task.")
	next_steps.append("Return to overview if the task changes or becomes unclear.")
	if not recommended_section.is_empty():
		next_steps.append("Recommended section: " + recommended_section + ".")
	return next_steps

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
