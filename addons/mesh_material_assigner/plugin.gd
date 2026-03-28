@tool
extends EditorPlugin

var _dock: VBoxContainer
var _group_input: LineEdit
var _use_override_checkbox: CheckBox
var _apply_button: Button
var _refresh_button: Button
var _status_label: Label
var _mapping_rows: VBoxContainer
var _mapping_controls: Array[Dictionary] = []

func _enter_tree() -> void:
	_build_dock()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)

func _exit_tree() -> void:
	if is_instance_valid(_dock):
		remove_control_from_docks(_dock)
		_dock.queue_free()
	_mapping_controls.clear()

func _build_dock() -> void:
	_dock = VBoxContainer.new()
	_dock.name = "Mesh Material"

	var title := Label.new()
	title.text = "Mesh Material Assigner"
	_dock.add_child(title)

	var group_label := Label.new()
	group_label.text = "Groups (comma separated)"
	_dock.add_child(group_label)

	_group_input = LineEdit.new()
	_group_input.placeholder_text = "MATERIAL_TARGETS"
	_group_input.text = "MATERIAL_TARGETS"
	_dock.add_child(_group_input)

	_use_override_checkbox = CheckBox.new()
	_use_override_checkbox.text = "Use material_override"
	_use_override_checkbox.button_pressed = true
	_dock.add_child(_use_override_checkbox)

	var map_label := Label.new()
	map_label.text = "Mappings (MeshName -> Material)"
	_dock.add_child(map_label)

	var mapping_header := HBoxContainer.new()
	var mesh_header := Label.new()
	mesh_header.text = "Mesh Name"
	mesh_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var material_header := Label.new()
	material_header.text = "Material"
	material_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mapping_header.add_child(mesh_header)
	mapping_header.add_child(material_header)
	_dock.add_child(mapping_header)

	_mapping_rows = VBoxContainer.new()
	_dock.add_child(_mapping_rows)

	_add_mapping_row("", null)

	var row_actions := HBoxContainer.new()
	var add_row_button := Button.new()
	add_row_button.text = "Add Row"
	add_row_button.pressed.connect(func() -> void:
		_add_mapping_row("", null)
	)
	row_actions.add_child(add_row_button)
	_dock.add_child(row_actions)

	var actions := HBoxContainer.new()
	_refresh_button = Button.new()
	_refresh_button.text = "Refresh From Selection"
	_refresh_button.pressed.connect(_on_refresh_pressed)
	actions.add_child(_refresh_button)

	_apply_button = Button.new()
	_apply_button.text = "Apply"
	_apply_button.pressed.connect(_on_apply_pressed)
	actions.add_child(_apply_button)
	_dock.add_child(actions)

	_status_label = Label.new()
	_status_label.text = "Ready."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dock.add_child(_status_label)

func _add_mapping_row(mesh_name: String, material: Material) -> void:
	var row := HBoxContainer.new()

	var mesh_name_input := LineEdit.new()
	mesh_name_input.placeholder_text = "MeshName"
	mesh_name_input.text = mesh_name
	mesh_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(mesh_name_input)

	var material_picker := EditorResourcePicker.new()
	material_picker.base_type = "Material"
	material_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if material != null:
		material_picker.edited_resource = material
	row.add_child(material_picker)

	var remove_button := Button.new()
	remove_button.text = "X"
	row.add_child(remove_button)

	_mapping_rows.add_child(row)

	var control_data := {
		"row": row,
		"mesh_name": mesh_name_input,
		"material": material_picker,
	}
	_mapping_controls.append(control_data)

	remove_button.pressed.connect(func() -> void:
		_remove_mapping_row(control_data)
	)

func _remove_mapping_row(control_data: Dictionary) -> void:
	if _mapping_controls.size() <= 1:
		(control_data["mesh_name"] as LineEdit).text = ""
		(control_data["material"] as EditorResourcePicker).edited_resource = null
		return

	_mapping_controls.erase(control_data)
	var row := control_data["row"] as HBoxContainer
	if is_instance_valid(row):
		row.queue_free()

func _on_refresh_pressed() -> void:
	var selected := get_editor_interface().get_selection().get_selected_nodes()
	if selected.is_empty():
		_status_label.text = "Select one or more nodes first."
		return

	var mesh_names: Dictionary = {}
	for node in selected:
		if node is Node:
			_collect_mesh_names(node, mesh_names)

	if mesh_names.is_empty():
		_status_label.text = "No MeshInstance3D found in selection."
		return

	_clear_mapping_rows()
	var sorted_names := mesh_names.keys()
	sorted_names.sort()
	for mesh_name in sorted_names:
		_add_mapping_row(mesh_name, null)

	_status_label.text = "Loaded %d mesh names from selection." % sorted_names.size()

func _collect_mesh_names(root: Node, names: Dictionary) -> void:
	for child in root.get_children():
		if child is MeshInstance3D:
			names[child.name] = true
		_collect_mesh_names(child, names)

func _clear_mapping_rows() -> void:
	for control_data in _mapping_controls:
		var row := control_data["row"] as HBoxContainer
		if is_instance_valid(row):
			row.queue_free()
	_mapping_controls.clear()

func _on_apply_pressed() -> void:
	var scene_root := get_editor_interface().get_edited_scene_root()
	if scene_root == null:
		_status_label.text = "No open scene."
		return

	var groups := _parse_groups(_group_input.text)
	if groups.is_empty():
		_status_label.text = "Provide at least one group name."
		return

	var mapping := _build_mapping()
	if mapping.is_empty():
		_status_label.text = "Add at least one valid mapping."
		return

	var visited: Dictionary = {}
	var touched_meshes: Array[MeshInstance3D] = []

	for group_name in groups:
		var nodes := scene_root.get_tree().get_nodes_in_group(group_name)
		for node in nodes:
			if not (node is Node):
				continue
			if node != scene_root and not scene_root.is_ancestor_of(node):
				continue
			if visited.has(node):
				continue
			visited[node] = true
			_collect_matching_meshes(node, mapping, touched_meshes)

	if touched_meshes.is_empty():
		_status_label.text = "No matching meshes found in those groups."
		return

	var unique_meshes: Array[MeshInstance3D] = []
	var mesh_seen: Dictionary = {}
	for mesh_instance in touched_meshes:
		var key := mesh_instance.get_instance_id()
		if mesh_seen.has(key):
			continue
		mesh_seen[key] = true
		unique_meshes.append(mesh_instance)

	var undo := get_undo_redo()
	undo.create_action("Assign Mesh Materials")

	var use_override := _use_override_checkbox.button_pressed
	for mesh_instance in unique_meshes:
		var material := mapping[mesh_instance.name] as Material
		if use_override:
			var previous_override := mesh_instance.material_override
			undo.add_do_method(mesh_instance, "set", "material_override", material)
			undo.add_undo_method(mesh_instance, "set", "material_override", previous_override)
		else:
			if mesh_instance.mesh == null:
				continue
			for surface_idx in range(mesh_instance.mesh.get_surface_count()):
				var previous_surface_material := mesh_instance.get_surface_override_material(surface_idx)
				undo.add_do_method(mesh_instance, "set_surface_override_material", surface_idx, material)
				undo.add_undo_method(mesh_instance, "set_surface_override_material", surface_idx, previous_surface_material)

	undo.commit_action()
	_status_label.text = "Updated %d meshes." % unique_meshes.size()

func _parse_groups(raw_text: String) -> PackedStringArray:
	var result := PackedStringArray()
	for token in raw_text.split(",", false):
		var group_name := token.strip_edges()
		if group_name != "":
			result.append(group_name)
	return result

func _build_mapping() -> Dictionary[String, Material]:
	var mapping: Dictionary[String, Material] = {}
	for control_data in _mapping_controls:
		var mesh_name := (control_data["mesh_name"] as LineEdit).text.strip_edges()
		var material := (control_data["material"] as EditorResourcePicker).edited_resource
		if mesh_name == "" or not (material is Material):
			continue
		mapping[mesh_name] = material
	return mapping

func _collect_matching_meshes(root: Node, mapping: Dictionary[String, Material], output: Array[MeshInstance3D]) -> void:
	for child in root.get_children():
		if child is MeshInstance3D and mapping.has(child.name):
			output.append(child)
		_collect_matching_meshes(child, mapping, output)
