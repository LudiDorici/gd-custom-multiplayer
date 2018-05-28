extends Control

const DEF_PORT = 4666
const PROTO_NAME = "ludus" # Only needed for websocket (sub-protocol name)
const USE_ENET = false # Change this to use ENet instead of Websockets

onready var _host_btn = $Panel/VBoxContainer/HBoxContainer2/HBoxContainer/Host
onready var _connect_btn = $Panel/VBoxContainer/HBoxContainer2/HBoxContainer/Connect
onready var _disconnect_btn = $Panel/VBoxContainer/HBoxContainer2/HBoxContainer/Disconnect
onready var _name_edit = $Panel/VBoxContainer/HBoxContainer/NameEdit
onready var _host_edit = $Panel/VBoxContainer/HBoxContainer2/Hostname
onready var _game = $Panel/VBoxContainer/Game

func _ready():
	$AcceptDialog.get_label().align = Label.ALIGN_CENTER
	$AcceptDialog.get_label().valign = Label.VALIGN_CENTER
	# As you can see, instead of calling get_tree().connect for network related
	# stuff we use mutltiplayer.connect . This way, IF (and only IF) the
	# MultiplayerAPI is customized, we use that instead of the global one.
	# This makes the custom MultiplayerAPI almost plug-n-play.
	multiplayer.connect("connection_failed", self, "_close_network")
	multiplayer.connect("connected_to_server", self, "_connected")
	multiplayer.connect("network_peer_disconnected", self, "_peer_disconnected")
	multiplayer.connect("network_peer_connected", self, "_peer_connected")
	multiplayer.connect("server_disconnected", self, "_close_network")

func _exit_tree():
	multiplayer.disconnect("connection_failed", self, "_close_network")
	multiplayer.disconnect("connected_to_server", self, "_connected")
	multiplayer.disconnect("network_peer_disconnected", self, "_peer_disconnected")
	multiplayer.disconnect("network_peer_connected", self, "_peer_connected")
	multiplayer.disconnect("server_disconnected", self, "_close_network")

func start_game():
	_host_btn.disabled = true
	_name_edit.editable = false
	_host_edit.editable = false
	_connect_btn.hide()
	_disconnect_btn.show()
	_game.start()

func stop_game():
	_host_btn.disabled = false
	_name_edit.editable = true
	_host_edit.editable = true
	_disconnect_btn.hide()
	_connect_btn.show()
	_game.stop()

func show_error():
	$AcceptDialog.show_modal()
	$AcceptDialog.get_close_button().grab_focus()

func _close_network():
	stop_game()
	multiplayer.set_network_peer(null)
	show_error()

func _connected():
	_game.rpc("set_player_name", _name_edit.text)

func _peer_connected(id):
	_game.on_peer_add(id)

func _peer_disconnected(id):
	_game.on_peer_del(id)

func start_server(port):
	var peer = null
	if USE_ENET:
		peer = NetworkedMultiplayerENet.new()
		peer.create_server(port)
	else:
		peer = WebSocketServer.new()
		peer.listen(port, PoolStringArray(["demo"]), true)
	# Same goes for things like:
	# get_tree().set_network_peer() -> multiplayer.set_network_peer()
	# Basically, anything networking related needs to be updated this way.
	# See the MultiplayerAPI docs for reference.
	multiplayer.set_network_peer(peer)
	_game.add_player(1, _name_edit.text)
	start_game()

func start_client(host, port):
	var peer = null
	if USE_ENET:
		peer = NetworkedMultiplayerENet.new()
		peer.create_client(host, port)
	else:
		peer = WebSocketClient.new()
		peer.connect_to_url("ws://%s:%s/" % [host, port], PoolStringArray(["demo"]), true)
	multiplayer.set_network_peer(peer)
	start_game()

func _on_Host_pressed():
	start_server(DEF_PORT)

func _on_Disconnect_pressed():
	_close_network()

func _on_Connect_pressed():
	start_client(_host_edit.text, DEF_PORT)