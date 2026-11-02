-- All player-facing text. English is the source language (EU/US audience).
--
-- How a string is chosen for a player:
--   1. a built-in dictionary for their language (English, Russian), else
--   2. Roblox automatic translation: the cloud localization table, uploaded
--      from localization/NeonGym.csv and auto-translated in Creator Hub, else
--   3. English.
-- Placeholders are {1}, {2}, ... (same format as Roblox localization tables).

local Strings = {}

Strings.en = {
	-- Machines
	["machine.dumbbells"] = "Dumbbells",
	["machine.treadmill"] = "Treadmill",
	["machine.bench"] = "Bench Press",
	["machine.abs"] = "Ab Bench",
	["machine.legpress"] = "Leg Press",
	["machine.pulldown"] = "Lat Pulldown",
	["machine.rower"] = "Rowing Machine",
	["machine.squat"] = "Barbell Squat",
	["machine.cable"] = "Cable Crossover",
	["machine.titan"] = "Titan Rig",
	["machine.pose"] = "Podium",

	-- Stats
	["stat.stamina"] = "Stamina",
	["stat.chest"] = "Chest",
	["stat.abs"] = "Abs",
	["stat.back"] = "Back",
	["stat.arms"] = "Arms",
	["stat.legs"] = "Legs",
	["stat.all"] = "Full body",

	-- Ranks
	["rank.1"] = "Rookie",
	["rank.2"] = "Beginner",
	["rank.3"] = "Amateur",
	["rank.4"] = "Strong Guy",
	["rank.5"] = "Athlete",
	["rank.6"] = "Bodybuilder",
	["rank.7"] = "Gym Champion",
	["rank.8"] = "Neon Titan",

	-- HUD
	["hud.strength"] = "🏆 Strength: {1}",
	["hud.rankBonus"] = "+{1}%",
	["hud.combo"] = "⚡ Pump +{1}%",
	["hud.next"] = "Next: {1} — muscles {2}, ❤ {3}",
	["hud.maxRank"] = "Max rank!",
	["hud.rankUp"] = "⬆ Rank up",
	["hud.tapHint"] = "Tap the screen to do a rep",
	["hud.runHint"] = "Running builds ❤ stamina",
	["hud.autoOn"] = "Auto: on",
	["hud.autoOff"] = "Auto: off",
	["hud.leave"] = "Leave (Q)",
	["hud.lb"] = "lb",
	["hud.weightTitle"] = "{1} · {2} lb · ❤ −{3} per rep",
	["hud.recommended"] = "Recommended: {1} {2}  (you have {3})",
	["hud.cardioTitle"] = "{1} · {2} mph · +{3} ❤ per sec",
	["hud.speed"] = "{1} mph",
	["hud.speedLocked"] = "🔒 {1} · ❤{2}",
	["hud.poseTitle"] = "🌟 You're on stage! Poses change by themselves",
	["hud.poseInfo"] = "Crowd: +{1} ⭐ every {2} s · players applaud (F): +{3} ⭐",
	["hud.poseHint"] = "More strength, louder crowd",
	["hud.maxPlates"] = "Max {1} plates",
	["hud.minPlates"] = "You need at least one plate",

	-- Popups and tags
	["popup.perfect"] = "Perfect weight!",
	["tag.locked"] = "🔒 Strength {1}",
	["tag.busy"] = "Taken",
	["tag.free"] = "Free — show your muscles!",

	-- Prompts
	["prompt.train"] = "Train",
	["prompt.start"] = "Start",
	["prompt.pose"] = "Step on stage",
	["prompt.applaud"] = "Applaud 👏",

	-- Server notifications
	["n.taken"] = "This machine is taken, find a free one",
	["n.stageTaken"] = "This spot on stage is taken",
	["n.locked"] = "🔒 Unlocks at {1} Strength",
	["n.onStage"] = "You're on stage! The crowd gives ⭐ Fame, players can applaud",
	["n.tooHeavy"] = "Too heavy! Need {1}, you have {2}",
	["n.noStamina"] = "Out of stamina! Rest or run on the treadmill",
	["n.tooFast"] = "Too fast — speed lowered",
	["n.plates"] = "You can use 1 to {1} plates",
	["n.needStamina"] = "Need {1} stamina",
	["n.rankUp"] = "New rank: {1}! Bonus +{2}%",
	["n.loadFail"] = "Couldn't load your progress — it won't be saved this session",
	["n.leaveFirst"] = "Leave the machine first",
	["n.alreadyApplauded"] = "You already applauded this performance",
	["n.applauded"] = "{1} applauds you! +{2} ⭐",

	-- NPC speech
	["npc.hello"] = "Hi, {1}! Welcome to Neon Gym!",
	["npc.g1"] = "Welcome to Neon Gym!",
	["npc.g2"] = "The gym is on the right, the podium on the left",
	["npc.g3"] = "The treadmill builds stamina — you need it for heavy weights",
	["npc.g4"] = "Pumped? Go to the podium and show off!",
	["npc.g5"] = "Tap the screen on a machine to do reps",
	["npc.c1"] = "One more!",
	["npc.c2"] = "You're the best!",
	["npc.c3"] = "Don't be afraid, it's easy for you!",
	["npc.c4"] = "Hang in there!",
	["npc.c5"] = "Great form!",
	["npc.c6"] = "What a pump!",
}

Strings.ru = {
	["machine.dumbbells"] = "Гантели",
	["machine.treadmill"] = "Беговая дорожка",
	["machine.bench"] = "Скамья для жима",
	["machine.abs"] = "Скамья для пресса",
	["machine.legpress"] = "Жим ногами",
	["machine.pulldown"] = "Тяга верхнего блока",
	["machine.rower"] = "Гребной тренажёр",
	["machine.squat"] = "Приседания со штангой",
	["machine.cable"] = "Кроссовер",
	["machine.titan"] = "Комплекс «Титан»",
	["machine.pose"] = "Подиум",

	["stat.stamina"] = "Выносливость",
	["stat.chest"] = "Грудь",
	["stat.abs"] = "Пресс",
	["stat.back"] = "Спина",
	["stat.arms"] = "Руки",
	["stat.legs"] = "Ноги",
	["stat.all"] = "Всё тело",

	["rank.1"] = "Новичок",
	["rank.2"] = "Начинающий",
	["rank.3"] = "Любитель",
	["rank.4"] = "Сильный парень",
	["rank.5"] = "Атлет",
	["rank.6"] = "Качок",
	["rank.7"] = "Чемпион зала",
	["rank.8"] = "Неоновый титан",

	["hud.strength"] = "🏆 Сила: {1}",
	["hud.rankBonus"] = "+{1}%",
	["hud.combo"] = "⚡ Пампинг +{1}%",
	["hud.next"] = "След.: {1} — мышцы {2}, ❤ {3}",
	["hud.maxRank"] = "Максимальный ранг!",
	["hud.rankUp"] = "⬆ Повысить ранг",
	["hud.tapHint"] = "Тапай по экрану — повтор",
	["hud.runHint"] = "Бег качает ❤ выносливость",
	["hud.autoOn"] = "Авто: вкл",
	["hud.autoOff"] = "Авто: выкл",
	["hud.leave"] = "Выйти (Q)",
	["hud.lb"] = "фунт.",
	["hud.weightTitle"] = "{1} · {2} фунт. · ❤ −{3} за повтор",
	["hud.recommended"] = "Рекомендуется: {1} {2}  (у тебя {3})",
	["hud.cardioTitle"] = "{1} · {2} миль/ч · +{3} ❤ в сек.",
	["hud.speed"] = "{1} миль/ч",
	["hud.speedLocked"] = "🔒 {1} · ❤{2}",
	["hud.poseTitle"] = "🌟 Ты на подиуме! Позы меняются сами",
	["hud.poseInfo"] = "Зрители: +{1} ⭐ каждые {2} с · игроки аплодируют (F): +{3} ⭐",
	["hud.poseHint"] = "Больше Силы — громче зал",
	["hud.maxPlates"] = "Максимум блинов — {1}",
	["hud.minPlates"] = "Нужен хотя бы один блин",

	["popup.perfect"] = "Идеальный вес!",
	["tag.locked"] = "🔒 Сила {1}",
	["tag.busy"] = "Занято",
	["tag.free"] = "Свободно — покажи мышцы!",

	["prompt.train"] = "Тренироваться",
	["prompt.start"] = "Начать",
	["prompt.pose"] = "Выйти на подиум",
	["prompt.applaud"] = "Аплодировать 👏",

	["n.taken"] = "Тренажёр занят, найди свободный",
	["n.stageTaken"] = "Это место на подиуме занято",
	["n.locked"] = "🔒 Откроется при Силе {1}",
	["n.onStage"] = "Ты на подиуме! Зрители дают ⭐ Славу, игроки могут аплодировать",
	["n.tooHeavy"] = "Слишком тяжело! Нужно {1}, у тебя {2}",
	["n.noStamina"] = "Нет выносливости! Отдохни или побегай на дорожке",
	["n.tooFast"] = "Слишком быстро — скорость снижена",
	["n.plates"] = "Можно от 1 до {1} блинов",
	["n.needStamina"] = "Нужно {1} выносливости",
	["n.rankUp"] = "Новый ранг: {1}! Бонус +{2}%",
	["n.loadFail"] = "Не удалось загрузить прогресс — он не будет сохранён в этой сессии",
	["n.leaveFirst"] = "Сначала сойди с тренажёра",
	["n.alreadyApplauded"] = "Ты уже аплодировал этому выходу",
	["n.applauded"] = "{1} аплодирует тебе! +{2} ⭐",

	["npc.hello"] = "Привет, {1}! Добро пожаловать в Neon Gym!",
	["npc.g1"] = "Добро пожаловать в Neon Gym!",
	["npc.g2"] = "Зал справа, подиум слева",
	["npc.g3"] = "Дорожка качает выносливость — без неё тяжёлый вес не поднять",
	["npc.g4"] = "Накачался? Иди на подиум и покажи мышцы!",
	["npc.g5"] = "Тапай по экрану на тренажёре, чтобы делать повторы",
	["npc.c1"] = "Давай, ещё разок!",
	["npc.c2"] = "Ты лучший!",
	["npc.c3"] = "Не бойся, тебе это легко!",
	["npc.c4"] = "Держись, почти!",
	["npc.c5"] = "Отличная техника!",
	["npc.c6"] = "Вот это пампинг!",
}

function Strings.format(text, args)
	return (string.gsub(text, "{(%d+)}", function(n)
		local v = args[tonumber(n)]
		return v ~= nil and tostring(v) or ""
	end))
end

-- Set on the client from LocalizationService:GetTranslatorForPlayerAsync
Strings.translator = nil

function Strings.t(lang, key, ...)
	local args = { ... }
	local builtin = Strings[lang]
	if type(builtin) == "table" and builtin[key] then
		return Strings.format(builtin[key], args)
	end
	if Strings.translator and lang ~= "en" then
		local ok, text = pcall(function()
			return Strings.translator:FormatByKey(key, args)
		end)
		if ok and type(text) == "string" and text ~= "" then
			return text
		end
	end
	return Strings.format(Strings.en[key] or key, args)
end

-- Language code from a Roblox locale id: "ru-ru" -> "ru", "de-de" -> "de"
function Strings.fromLocale(localeId)
	local code = string.lower(string.sub(localeId or "en", 1, 2))
	return code ~= "" and code or "en"
end


return Strings
