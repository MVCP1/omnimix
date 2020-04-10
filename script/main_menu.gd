extends CanvasLayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	network.connect("server_created", self, "_on_ready_to_play")
	network.connect("join_success", self, "_on_ready_to_play")
	network.connect("join_fail", self, "_on_join_fail")
	get_tree().paused = false
	pass # Replace with function body.

func _on_ready_to_play():
	get_tree().change_scene("res://scenes/game_world.tscn")

func _on_join_fail():
	print("Failed to join server")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_btCreate_pressed():
	# Properly set the local player information
	set_player_info()
	
	# Gather values from the GUI and fill the network.server_info dictionary
	if (!$PanelHost/txtServerName.text.empty()):
		network.server_info.name = $PanelHost/txtServerName.text
	network.server_info.max_players = int($PanelHost/txtMaxPlayers.value)
	network.server_info.used_port = int($PanelHost/txtServerPort.text)
	
	# And create the server, using the function previously added into the code
	network.create_server()
	pass # Replace with function body.


func _on_btJoin_pressed():
	# Properly set the local player information
	set_player_info()
	
	var port = int($PanelJoin/txtJoinPort.text)
	var ip = $PanelJoin/txtJoinIP.text
	network.join_server(ip, port)
	pass # Replace with function body.



func set_player_info():
	if (!$PanelPlayer/txtPlayerName.text.empty()):
		gamestate.player_info.name = $PanelPlayer/txtPlayerName.text
	gamestate.player_info.char_color = $PanelPlayer/btColor.color


func _on_btColor_color_changed(color):
	$PanelPlayer/PlayerIcon.modulate = color
	pass # Replace with function body.


func _on_btDefaultColor_pressed():
	$PanelPlayer/btColor.color = Color(randf(), randf(), randf())
	$PanelPlayer/PlayerIcon.modulate = $PanelPlayer/btColor.color
	pass # Replace with function body.
