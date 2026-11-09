extends Node
## 存档：每日结束后自动写 JSON；暂停菜单也能手动存。存的都是某一天清晨的状态。

const SAVE_PATH := "user://save.json"
const PLAYTEST_PATH := "user://playtest.jsonl"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(data := GameState.to_dict()) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))


## 游玩途中手动存档：回到今天早上。
func save_checkpoint() -> void:
	save_game(GameState.morning)


## 存档里是这一局的第几天；没有存档或是别的局的存档时为 0。
func saved_day() -> int:
	if not has_save():
		return 0
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if data is not Dictionary or int(data.get("run_seed", 0)) != GameState.run_seed:
		return 0
	return int(data.day)


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


## 里程碑关卡：“第一个月底是否想玩下个月”，每局追加一行，供试玩后统计。
func record_playtest(wants_next: bool) -> void:
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(PLAYTEST_PATH) else FileAccess.WRITE
	var file := FileAccess.open(PLAYTEST_PATH, mode)
	file.seek_end()
	file.store_line(JSON.stringify({
		"last_day": GameState.LAST_DAY, "wants_next": wants_next, "savings": GameState.savings, "conscience": GameState.conscience,
		"boss_trust": GameState.boss_trust, "family_state": GameState.family_state,
		"decisions": GameState.decision_log.size(), "hires": GameState.hires.size(),
	}))
