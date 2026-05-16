extends Control

var settings_file = ConfigFile.new()
var vsync: int = 0
var window_mode: int = 0
var audio: Vector3 = Vector3(70.0, 70.0, 70.0)
var display_resolution : Vector2i = DisplayServer.screen_get_size()

@onready var resolution_option_button = get_node("%Resolution_Optionbutton")
@onready var window_mode_option_button = get_node("%WindowMode_Optionbutton")
@onready var option_container = get_node("%OptionContainer")
@onready var main_container = get_node("%MainContainer")
@onready var general_scroll = get_node("%General_HScrollBar")
@onready var music_scroll = get_node("%Music_HScrollBar")
@onready var sfx_scroll = get_node("%SFX_HScrollBar")
var maingame = preload("res://Scenes/main.tscn").instantiate()

func _get_resolution(index) -> Vector2i:
	var resolution_arr = resolution_option_button.get_item_text(index).split("x")
	return Vector2i(int(resolution_arr[0]), int(resolution_arr[1]))


func _check_resolution(resolution: Vector2i):
	for i in resolution_option_button.get_item_count():
		if _get_resolution(i) == resolution:
			return i


func _first_time() -> void:
	DisplayServer.window_set_size(DisplayServer.screen_get_size())
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	DisplayServer.window_set_vsync_mode(vsync)
	resolution_option_button.select(_check_resolution(DisplayServer.screen_get_size()))
	# -- Video
	settings_file.set_value("VIDEO", "Resolution", _get_resolution(resolution_option_button.get_selected()))
	settings_file.set_value("VIDEO", "vsync", vsync)
	settings_file.set_value("VIDEO", "Window Mode", window_mode)
	settings_file.set_value("VIDEO", "Graphics", 0)
	settings_file.set_value("VIDEO", "Color blind", 0)
	# -- Audio
	settings_file.set_value("audio", "General", audio.x)
	settings_file.set_value("audio", "Music", audio.y)
	settings_file.set_value("audio", "SFX", audio.z)
	settings_file.save("res://settings.cfg")


func _load_settings():
	if settings_file.load("res://settings.cfg") != OK:
		_first_time()
	else:
		display_resolution = settings_file.get_value("VIDEO", "Resolution")
		get_window().size = display_resolution
		window_mode = settings_file.get_value("VIDEO", "Window Mode")
		window_mode_option_button.select(window_mode)
		DisplayServer.window_set_mode(window_mode as DisplayServer.WindowMode)
		vsync = settings_file.get_value("VIDEO", "vsync")
		audio.x = settings_file.get_value("audio", "General")
		audio.y = settings_file.get_value("audio", "Music")
		audio.z = settings_file.get_value("audio", "SFX")
		general_scroll.value = audio.x
		music_scroll.value = audio.y
		sfx_scroll.value = audio.z


func _save_settings() -> void:
	settings_file.set_value("VIDEO", "Resolution", _get_resolution(resolution_option_button.get_selected()))
	settings_file.set_value("VIDEO", "vsync", vsync)
	settings_file.set_value("VIDEO", "Window Mode", window_mode_option_button.get_selected())
	settings_file.set_value("VIDEO", "Graphics", 0)
	settings_file.set_value("VIDEO", "Color blind", 0)
	settings_file.set_value("audio", "General", audio.x)
	settings_file.set_value("audio", "Music", audio.y)
	settings_file.set_value("audio", "SFX", audio.z)
	settings_file.save("res://settings.cfg")


func _ready():
	window_mode_option_button.add_item("Windowed", 0)
	window_mode_option_button.add_item("Minimized", 1)
	window_mode_option_button.add_item("Maximized", 2)
	window_mode_option_button.add_item("Fullscreen", 3)
	window_mode_option_button.add_item("Exclusive Fullscreen", 4)
	_load_settings()
	resolution_option_button.select(_check_resolution(display_resolution))


func _on_start_button_pressed():
	get_tree().root.add_child(maingame)
	queue_free()
	


func _on_option_button_pressed():
	option_container.visible = true
	main_container.visible = false


func _on_exit_button_pressed():
	get_tree().quit()


# -- VIDEO TAB --

func _on_resolution_optionbutton_item_selected(index):
	get_window().size = _get_resolution(index)


func _on_window_mode_optionbutton_item_selected(index):
	window_mode = index
	DisplayServer.window_set_mode(window_mode as DisplayServer.WindowMode)


func _on_preset_h_slider_value_changed(_value):
	pass


# -- AUDIO TAB --

func _on_general_h_scroll_bar_value_changed(value):
	audio.x = value


func _on_music_h_scroll_bar_value_changed(value):
	audio.y = value


func _on_sfx_h_scroll_bar_value_changed(value):
	audio.z = value


# -- Save and Return buttons --

func _on_return_button_pressed():
	main_container.visible = true
	option_container.visible = false


func _on_apply_button_pressed():
	main_container.visible = true
	option_container.visible = false
	_save_settings()


func _on_vsync_option_button_item_selected(index):
	vsync = index
