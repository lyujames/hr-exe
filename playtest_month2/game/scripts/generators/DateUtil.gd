class_name DateUtil
## 日期工具。全局日期用 "YYYY-MM-DD"，工作经历用 "YYYY-MM"。

const WEEKDAYS := ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]


static func parse(date: String) -> Vector3i:
	var parts := date.split("-")
	return Vector3i(int(parts[0]), int(parts[1]), int(parts[2]) if parts.size() > 2 else 1)


static func format(date: Vector3i) -> String:
	return "%04d-%02d-%02d" % [date.x, date.y, date.z]


static func age_on(birth: String, today: String) -> int:
	var b := parse(birth)
	var t := parse(today)
	var age := t.x - b.x
	if t.y < b.y or (t.y == b.y and t.z < b.z):
		age -= 1
	return age


static func add_days(date: String, days: int) -> String:
	var unix := Time.get_unix_time_from_datetime_string(date) + days * 86400
	return Time.get_date_string_from_unix_time(unix)


static func years_before(today: String, years: int, extra_days := 0) -> String:
	var t := parse(today)
	return add_days(format(Vector3i(t.x - years, t.y, t.z)), extra_days)


static func weekday(date: String) -> String:
	var unix := Time.get_unix_time_from_datetime_string(date)
	return WEEKDAYS[Time.get_date_dict_from_unix_time(unix).weekday]


static func month_index(date: String) -> int:
	var d := parse(date)
	return d.x * 12 + d.y - 1


static func month_string(index: int) -> String:
	return "%04d-%02d" % [floori(index / 12.0), index % 12 + 1]
