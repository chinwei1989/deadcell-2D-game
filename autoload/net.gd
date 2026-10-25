extends Node
## Co-op session management (PLAN.md section 28). For now: LAN sessions over ENet for
## development. Epic Online Services will provide the production MultiplayerPeer later;
## game code only talks to this autoload and Godot's `multiplayer` API, so the transport
## can change without touching gameplay.
##
## Authority rule: the host (peer 1) owns enemies, level state and loot; each player owns
## their own character (set with set_multiplayer_authority(peer_id)).

signal session_started
signal session_ended
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)

const DEFAULT_PORT := 24680
const MAX_PLAYERS := 2


func _ready() -> void:
	multiplayer.peer_connected.connect(func(id: int) -> void: peer_joined.emit(id))
	multiplayer.peer_disconnected.connect(func(id: int) -> void: peer_left.emit(id))
	multiplayer.server_disconnected.connect(leave)


func host_lan(port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS - 1)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	session_started.emit()
	return OK


func join_lan(address: String, port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	session_started.emit()
	return OK


func leave() -> void:
	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	session_ended.emit()


func is_online() -> bool:
	return not multiplayer.multiplayer_peer is OfflineMultiplayerPeer


func is_host() -> bool:
	return multiplayer.is_server()


func local_peer_id() -> int:
	return multiplayer.get_unique_id()
