extends Node

var copy_id_to_clipboard := true
var print_console := true

const Utility := preload("res://tests/functional/utility/utility.gd")


func fetch() -> void:
	var id: String = $"UI/Parameters/ID Parameter/ID".text
	var user := await GotmUser.fetch(id)
	if !user:
		push_error("Could not fetch user with id: ", id)
		return

	if copy_id_to_clipboard:
		DisplayServer.clipboard_set(user.id)
	if print_console:
		print("GotmUser fetched...")
		print(Utility.user_to_string(user))



func _check_buttons(_param = null) -> void:
	# Fetch User Button
	if $"UI/Parameters/ID Parameter/ID".text != "":
		$UI/Menu/FetchUser.disabled = false
	else:
		$UI/Menu/FetchUser.disabled = true


func _on_copy_id_toggled(button_pressed: bool):
	copy_id_to_clipboard = button_pressed


func _on_console_print_toggled(button_pressed: bool) -> void:
	print_console = button_pressed
