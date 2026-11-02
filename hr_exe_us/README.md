# HR.exe US — 美国版垂直切片

美国版独立开发，项目最后再与中国版 `../hr_exe` 合并。内容为英文，Godot 4.7。

## 运行

用 Godot 4.x 打开本目录的 `project.godot`，按 F5。工程名是 “HR.exe US”，存档和中国版互不影响。

## 与中国版的差异

- **简历：** 没有照片和出生日期（REMOVED BY LEGAL），年龄只能从毕业年份反推。
- **工作资格（简历第 3 页）：** 国籍、身份、有效期。第 2 天起身份必须在当天有效，TN 只限加拿大和墨西哥公民。
- **签证政策：** 第 3 天的 `RuleVisaPolicy` 不进手册（`unlisted`）。H-1B 停招只登在第 2 晚的报纸上，OPT 剩余不足 30 天拒绝只写在桌面 Legal 托盘里，不打开就看不到。
- **姓名：** 按文化来源成组，只作暗示。选组与国籍、身份互相独立，也不接任何规则，测试会确认各组的公民比例和通过率没有明显差别。
- **第 3 天规则：** `RuleCultureFit` 取代年龄规则，毕业超过 14 年拒绝。
- **薪资：** 年薪 + 奖金百分比，总包上限 $110,000。`Candidate.salary_months` 换成 `bonus_pct`。
- **问题卡：** 共 10 张，含擦边问题 “Where are you from, originally?”，每张带 `concept` 和 `bare_text`（剥掉修辞后的裸问题，留给终章）。
- **诉讼：** 玩家问的和 Tyler 问的都累积 `lawsuit_risk`，当晚才由法务提示；累积到 2 赔 $150，一局一次。
- **主管：** Tyler 不占问题名额，三张卡问完后补一句“随便问问”。
- **否决：** 候选人 `performance < 45` 时，点录用会被 “not a culture fit” 否决，无视评分表；硬顶要扣老板信任。
- **数值：** 底薪 $150、计件 $2、违规 −$25、房租 $90，账单是学贷和父亲的急诊自付。

## 测试

    godot --headless --path . res://tests/RunTests.tscn
    godot --path . res://tests/PlayBot.tscn -- <截图目录>

## 合并说明

- 开局 offer 和 `Region` 抽象留到合并时做，现在美国版的常量直接写在代码里。
- 合并时把 `QuestionCard.concept` / `bare_text` 补到中国卡上，同一 concept 即同题异卷。
- 需要合并的代码差异：`Candidate` 的薪资字段、`ResumeDoc` 的简历字段、`InterviewRoom` 的主管时机与否决、
  `GameState` 的和解逻辑、`DateUtil` 的星期和月份。
- 所有界面文字目前写死在脚本里。美国版要出中文、中国版要出英文，都得等合并时走 `tr()`。
