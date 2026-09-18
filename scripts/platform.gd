class_name LabPlatform
extends Node

signal state_changed
signal ad_finished

var language = "ru"
var suspended = false
var mobile = false
var bridge: JavaScriptObject
var callback: JavaScriptObject
var storage_key = "kinetic_lab_v1"

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		bridge=JavaScriptBridge.get_interface("KineticBridge")
		if bridge:
			callback=JavaScriptBridge.create_callback(_web_event)
			bridge.subscribe(callback)
			mobile=bool(bridge.isMobile())
	else:
		language=system_language()

func system_language() -> String:
	# Outside the portal the operating system locale is the only hint available.
	return "ru" if OS.get_locale_language()=="ru" else "en"

func set_page_language(value: String) -> void:
	if bridge: bridge.setLanguage(value)

func _web_event(args: Array) -> void:
	if args.is_empty(): return
	var data=JSON.parse_string(str(args[0]))
	if not data is Dictionary: return
	language=str(data.get("language","ru"))
	suspended=bool(data.get("paused",false))
	state_changed.emit()
	if data.get("event","")=="ad_closed": ad_finished.emit()

func ready_for_player() -> void:
	if bridge: bridge.gameReady()

func gameplay(running: bool) -> void:
	if bridge: bridge.gameplay(running)

func request_fullscreen() -> void:
	if bridge: bridge.fullscreen()

func show_ad() -> void:
	if bridge: bridge.interstitial()
	else: ad_finished.emit()

func load_data() -> Dictionary:
	var raw=""
	if bridge: raw=str(bridge.load())
	elif FileAccess.file_exists("user://progress.json"):
		raw=FileAccess.get_file_as_string("user://progress.json")
	var parsed=JSON.parse_string(raw) if not raw.is_empty() else null
	return parsed if parsed is Dictionary else {}

func save_data(data: Dictionary) -> bool:
	var raw=JSON.stringify(data)
	if bridge: return bool(bridge.save(raw))
	var file=FileAccess.open("user://progress.json",FileAccess.WRITE)
	if file:
		file.store_string(raw)
		return true
	return false

func _notification(what: int) -> void:
	if OS.has_feature("web"): return
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		suspended=true
		state_changed.emit()
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN:
		suspended=false
		state_changed.emit()
