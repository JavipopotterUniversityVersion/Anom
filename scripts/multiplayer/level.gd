extends Node3D
class_name Level

@export var players_container: Node3D
@onready var main_menu: MainMenuUI = $MainMenuUI
@export var player_scene: PackedScene

@onready var multiplayer_chat: MultiplayerChatUI = $MultiplayerChatUI
@onready var inventory_ui: InventoryUI = $InventoryUI
@export var house_manager:HouseManager

var chat_visible = false
var inventory_visible = false

# Debug command system
var anomaly_aliases: Dictionary = {
	"furniture": &"DISSAPEARED_FURNITURE",
	"dissapeared_furniture": &"DISSAPEARED_FURNITURE",
	"dissapeared": &"DISSAPEARED_FURNITURE",
	"doll": &"DOLL",
	"peripheral": &"PERIPHERIAL",
	"peripheral_material": &"PERIPHERIAL",
	"peripherial": &"PERIPHERIAL",
	"floor": &"SMALL_FLOOR",
	"small_floor": &"SMALL_FLOOR",
}

func _ready():
	if DisplayServer.get_name() == "headless":
		print("Dedicated server starting...")
		Network.start_host("")
		
		print("peer:", multiplayer.multiplayer_peer)
		print("is_server:", multiplayer.is_server(), " unique_id:", multiplayer.get_unique_id())
		
		for ip in IP.get_local_addresses():
			print("Server IP:", ip)

	multiplayer_chat.hide()
	main_menu.show_menu()
	multiplayer_chat.set_process_input(true)

	main_menu.host_pressed.connect(_on_host_pressed)
	main_menu.join_pressed.connect(_on_join_pressed)
	main_menu.quit_pressed.connect(_on_quit_pressed)

	if inventory_ui:
		inventory_ui.inventory_closed.connect(_on_inventory_closed)

	if multiplayer_chat:
		multiplayer_chat.message_sent.connect(_on_chat_message_sent)

	if not multiplayer.is_server():
		return

	Network.connect("player_connected", Callable(self, "_on_player_connected"))
	multiplayer.peer_disconnected.connect(_remove_player)

func _on_player_connected(peer_id, player_info):
	_add_player(peer_id, player_info)

func _on_host_pressed(nickname: String):
	main_menu.hide_menu()
	Network.start_host(nickname)

func _on_join_pressed(nickname: String, address: String):
	main_menu.hide_menu()
	Network.join_game(nickname, address)

func _add_player(id: int, player_info : Dictionary):
	if DisplayServer.get_name() == "headless" and id == 1:
		return

	if players_container.has_node(str(id)):
		return

	var player = GlobalData.CHARACTERS[player_info["character"]].instantiate()
	player.name = str(id)
	player.position = Vector3.ZERO
	
	players_container.add_child(player, true)

	var nick = Network.players[id]["nick"]
	player.nickname.text = nick

func _remove_player(id):
	if not multiplayer.is_server() or not players_container.has_node(str(id)):
		return
	var player_node = players_container.get_node(str(id))
	if player_node:
		player_node.queue_free()

func _on_quit_pressed() -> void:
	get_tree().quit()

# ---------- MULTIPLAYER CHAT ----------
func toggle_chat():
	if main_menu.is_menu_visible():
		return

	multiplayer_chat.toggle_chat()
	chat_visible = multiplayer_chat.is_chat_visible()

func is_chat_visible() -> bool:
	return multiplayer_chat.is_chat_visible()

func _input(event):
	if event.is_action_pressed("toggle_chat"):
		toggle_chat()
	elif chat_visible and multiplayer_chat.message.has_focus():
		if event is InputEventKey and event.keycode == KEY_ENTER and event.pressed:
			multiplayer_chat._on_send_pressed()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		toggle_inventory()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		_debug_add_item()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F2:
		_debug_print_inventory()

func _on_chat_message_sent(message_text: String) -> void:
	var trimmed_message = message_text.strip_edges()
	if trimmed_message == "":
		return # do not send empty messages

	# Handle debug commands
	if trimmed_message.begins_with("/"):
		_execute_debug_command(trimmed_message)
		return  # Don't broadcast debug commands
	
	var nick = Network.players[multiplayer.get_unique_id()]["nick"]
	rpc("msg_rpc", nick, trimmed_message)

func _execute_debug_command(command_text: String) -> void:
	# Parse command: /command arg1 arg2 ...
	var parts = command_text.trim_prefix("/").split(" ")
	var command = parts[0].to_lower()
	var args = parts.slice(1) if parts.size() > 1 else []
	
	match command:
		"anom":
			_handle_anom_command(args)
		"help":
			_show_help()
		_:
			GuideUI.show_message("Comando desconocido: %s. Usa /help para ver comandos." % command, 3.0)

func _handle_anom_command(args: Array) -> void:
	# Only server can execute anomalies
	if not multiplayer.is_server():
		GuideUI.show_message("Solo el servidor puede ejecutar anomalías.", 3.0)
		return
	
	# Get reference to house manager
	if not house_manager:
		GuideUI.show_message("Error: No se encontró HouseManager.", 3.0)
		return
	
	if args.is_empty():
		GuideUI.show_message("Uso: /anom [nombre|random|list|current|reset]", 3.0)
		return
	
	var subcommand = args[0].to_lower()
	
	match subcommand:
		"list":
			_show_anomaly_list()
		"current":
			_show_current_anomaly()
		"reset":
			_reset_anomalies()
		"random":
			_trigger_random_anomaly()
		_:
			_trigger_specific_anomaly(subcommand)

func _trigger_specific_anomaly(anomaly_name: String) -> void:
	var anomaly_name_lower = anomaly_name.to_lower()
	
	# Check if it's an alias
	if anomaly_aliases.has(anomaly_name_lower):
		var actual_anomaly = anomaly_aliases[anomaly_name_lower]
		
		# Check if anomaly exists
		if not house_manager.anomalies.has(actual_anomaly):
			GuideUI.show_message("Anomalía no encontrada: %s" % anomaly_name, 3.0)
			return
		
		# Build payload
		var payload = house_manager._build_anomaly_payload(actual_anomaly)
		
		# Execute via RPC
		house_manager._apply_anomaly_sync.rpc(actual_anomaly, payload)
		GuideUI.show_message("✓ Anomalía ejecutada: %s" % anomaly_name, 2.0)
	else:
		GuideUI.show_message("Anomalía desconocida: %s. Usa /anom list" % anomaly_name, 3.0)

func _trigger_random_anomaly() -> void:
	house_manager.anomalize()
	GuideUI.show_message("✓ Anomalía aleatoria ejecutada", 2.0)

func _show_anomaly_list() -> void:
	var list_text = "Anomalías disponibles:\n"
	for anomaly_key in house_manager.anomalies.keys():
		list_text += "  • %s\n" % _format_anomaly_name(anomaly_key)
	list_text += "\nAliases: furniture, doll, peripheral, floor, random"
	GuideUI.show_message(list_text, 5.0)

func _show_current_anomaly() -> void:
	if house_manager.current_anomaly:
		GuideUI.show_message("Anomalía actual: %s" % _format_anomaly_name(house_manager.selected_anomaly), 3.0)
	else:
		GuideUI.show_message("No hay anomalía activa actualmente.", 3.0)

func _reset_anomalies() -> void:
	house_manager.reset()
	GuideUI.show_message("✓ Anomalías resetadas", 2.0)

func _format_anomaly_name(anomaly_key: StringName) -> String:
	match anomaly_key:
		&"DISSAPEARED_FURNITURE":
			return "Muebles Desaparecidos (furniture)"
		&"DOLL":
			return "Muñeca (doll)"
		&"PERIPHERIAL":
			return "Material Periférico (peripheral)"
		&"SMALL_FLOOR":
			return "Piso Pequeño (floor)"
		_:
			return str(anomaly_key)

func _show_help() -> void:
	var help_text = """Comandos disponibles:
/anom [nombre]  - Ejecuta anomalía específica
/anom random    - Ejecuta anomalía aleatoria
/anom list      - Lista todas las anomalías
/anom current   - Muestra anomalía activa
/anom reset     - Resetea anomalías disponibles
/help           - Muestra este mensaje

Aliases: furniture, doll, peripheral, floor"""
	GuideUI.show_message(help_text, 6.0)

@rpc("any_peer", "call_local")
func msg_rpc(nick, msg):
	multiplayer_chat.add_message(nick, msg)

# ---------- INVENTORY SYSTEM ----------
func toggle_inventory():
	if main_menu.is_menu_visible():
		return

	var local_player = _get_local_player()
	if not local_player:
		return

	inventory_visible = !inventory_visible
	if inventory_visible:
		inventory_ui.open_inventory(local_player)
	else:
		inventory_ui.close_inventory()

func is_inventory_visible() -> bool:
	return inventory_visible

# Additional helper for testing
func _notification(what):
	if what == NOTIFICATION_READY:
		print("Inventory System Controls:")
		print("  B - Toggle inventory")
		print("  F1 - Add random test item (debug)")
		print("  F2 - Print inventory contents (debug)")
		print("\nDebug Commands (chat):")
		print("  /help - Show all available commands")
		print("  /anom [name] - Execute specific anomaly")
		print("  /anom random - Execute random anomaly")
		print("  /anom list - List all anomalies")
		print("  /anom current - Show current anomaly")
		print("  /anom reset - Reset anomalies")

func _on_inventory_closed():
	inventory_visible = false

func update_local_inventory_display():
	if inventory_ui:
		# Always refresh if the UI exists, regardless of visibility
		inventory_ui.refresh_display()
		print("Debug: Inventory display updated from server sync")

func _get_local_player() -> Character:
	var local_player_id = multiplayer.get_unique_id()
	if players_container.has_node(str(local_player_id)):
		return players_container.get_node(str(local_player_id)) as Character
	return null

# Debug functions for testing inventory system
func _debug_add_item():
	var local_player = _get_local_player()
	if local_player:
		var test_items = ["iron_sword", "health_potion", "leather_armor", "magic_gem", "iron_pickaxe"]
		var random_item = test_items[randi() % test_items.size()]
		print("Debug: Requesting to add ", random_item, " to player ", local_player.name, " (authority: ", local_player.get_multiplayer_authority(), ")")
		local_player.request_add_item.rpc_id(1, random_item, 1)
	else:
		print("Debug: No local player found!")

func _debug_print_inventory():
	var local_player = _get_local_player()
	if local_player and local_player.get_inventory():
		var inventory = local_player.get_inventory()
		print("=== Inventory Debug ===")
		for i in range(inventory.slots.size()):
			var slot = inventory.get_slot(i)
			if slot and not slot.is_empty():
				print("Slot ", i, ": ", slot.item_id, " x", slot.quantity)
		print("=====================")
	else:
		print("No inventory found for local player")
