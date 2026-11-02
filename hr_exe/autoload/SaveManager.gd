extends Node
## 存档：每日结束后自动写 JSON；存的是下一天清晨的状态。

const SAVE_PATH := "user://save.json"
const PLAYTEST_PATH := "user://playtest.jsonl"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(GameState.to_dict()))


func load_game() -> bool:
	if not has_save():
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if data is not Dictionary:
		return false
	GameState.load_dict(data)
	return true


func clear() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


## 里程碑关卡：“第 3 天结束时是否想玩第 4 天”，每局追加一行，供试玩后统计。
func record_playtest(wants_day_4: bool) -> void:
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(PLAYTEST_PATH) else FileAccess.WRITE
	var file := FileAccess.open(PLAYTEST_PATH, mode)
	file.seek_end()
	file.store_line(JSON.stringify({
		"wants_day_4": wants_day_4, "savings": GameState.savings, "conscience": GameState.conscience,
		"boss_trust": GameState.boss_trust, "family_state": GameState.family_state,
		"decisions": GameState.decision_log.size(), "hires": GameState.hires.size(),
	}))
