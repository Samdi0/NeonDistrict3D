extends Node
class_name NetworkManager

signal connection_message(message: String)

const DEFAULT_PORT := 24567

func host_game(port: int = DEFAULT_PORT) -> Error:
    if OS.has_feature("web"):
        connection_message.emit("Браузер не может быть хостом. Запусти сервер на ПК или VPS.")
        return ERR_UNAVAILABLE
    var enet := ENetMultiplayerPeer.new()
    var err := enet.create_server(port, 8)
    if err != OK:
        connection_message.emit("Не удалось создать сервер")
        return err
    var peer: MultiplayerPeer = enet
    multiplayer.multiplayer_peer = peer
    connection_message.emit("Сервер запущен. Порт: %d" % port)
    return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
    var peer: MultiplayerPeer
    if OS.has_feature("web"):
        var ws := WebSocketMultiplayerPeer.new()
        var url := address
        if not url.begins_with("ws://") and not url.begins_with("wss://"):
            url = "wss://" + address
        var host_port := url.trim_prefix("wss://").trim_prefix("ws://")
        if not host_port.contains(":"):
            url += ":%d" % port
        var web_error := ws.create_client(url)
        if web_error != OK:
            connection_message.emit("Не удалось подключиться к WebSocket")
            return web_error
        peer = ws
    else:
        var enet := ENetMultiplayerPeer.new()
        var enet_error := enet.create_client(address, port)
        if enet_error != OK:
            connection_message.emit("Не удалось подключиться к серверу")
            return enet_error
        peer = enet
    multiplayer.multiplayer_peer = peer
    connection_message.emit("Подключение к %s..." % address)
    return OK

func disconnect_game() -> void:
    multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
    connection_message.emit("Отключено от сетевой игры")
