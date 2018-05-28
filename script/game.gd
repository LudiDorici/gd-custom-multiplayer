### This is just a simple turn-based demo game
### No very much to do beside pressing a button :).

extends Control

const _crown = preload("res://img/crown.png")

onready var _list = $HBoxContainer/VBoxContainer/PlayerList/NameList
onready var _ping_list = $HBoxContainer/VBoxContainer/PlayerList/PingList
onready var _action = $HBoxContainer/VBoxContainer/Action

var _players = []
var _turn = -1

master func set_player_name(player_name):
	var sender = multiplayer.get_rpc_sender_id()
	rpc("update_player_name", sender, player_name)

sync func update_player_name(player, player_name):
	var pos = _players.find(player)
	if pos != -1:
		_list.set_item_text(pos, player_name)

master func request_action(action):
	var sender = multiplayer.get_rpc_sender_id()
	if _players[_turn] != multiplayer.get_rpc_sender_id():
		_rpc("_log", "Someone is trying to cheat! %s" % str(sender))
		return
	do_action(action)
	next_turn()

sync func do_action(action):
	var player_name = _list.get_item_text(_turn)
	_log("%s: %ss %d" % [player_name, action, randi() % 100])

sync func set_turn(turn):
	_turn = turn
	if turn >= _players.size():
		return
	for i in range(0, _players.size()):
		if i == turn:
			_list.set_item_icon(i, _crown)
		else:
			_list.set_item_icon(i, null)
	_action.disabled = _players[turn] != multiplayer.get_network_unique_id()

sync func del_player(id):
	var pos = _players.find(id)
	if pos == -1:
		return
	_players.remove(pos)
	_list.remove_item(pos)
	_ping_list.remove_item(pos)
	if _turn > pos:
		_turn -= 1
	if _turn >= _players.size():
		_turn = 0
	if multiplayer.is_network_server():
		rpc("set_turn", _turn)

sync func add_player(id, player_name=""):
	if multiplayer.is_network_server() and id != 1:
		_log("%s:%s connected!" % [
			multiplayer.network_peer.get_peer_address(id),
			multiplayer.network_peer.get_peer_port(id)
		])
	_players.append(id)
	if player_name == "":
		_list.add_item("... connecting ...", null, false)
	else:
		_list.add_item(player_name, null, false)
	_ping_list.add_item("-", null, false)

func get_player_name(pos):
	if pos < _list.get_item_count():
		return _list.get_item_text(pos)
	else:
		return "Error!"

func next_turn():
	_turn += 1
	if _turn >= _players.size():
		_turn = 0
	rpc("set_turn", _turn)

func start():
	set_turn(0)

func stop():
	_players.clear()
	_list.clear()
	_ping_list.clear()
	_turn = 0
	_action.disabled = true

func on_peer_add(id):
	if not multiplayer.is_network_server():
		return
	for i in range(0, _players.size()):
		rpc_id(id, "add_player", _players[i], get_player_name(i))
	rpc("add_player", id)
	rpc_id(id, "set_turn", _turn)

func on_peer_del(id):
	if not multiplayer.is_network_server():
		return
	rpc("del_player", id)

sync func _log(what):
	$HBoxContainer/RichTextLabel.add_text(what + "\n")

func _on_Action_pressed():
	if multiplayer.is_network_server():
		rpc("do_action", "roll")
		next_turn()
	else:
		rpc("request_action", "roll")

func _on_NameList_item_activated(index):
	if multiplayer.is_network_server() and _players[index] != 1:
		multiplayer.network_peer.disconnect_peer(_players[index])
