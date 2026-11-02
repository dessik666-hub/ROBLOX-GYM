-- All player-facing text in English and Russian.
-- English is the default (EU/US audience); Russian turns on for ru locales
-- or with the 🌐 button. World signs and posters stay English for everyone.
--
-- Strings.t(lang, key, ...) formats with string.format; every placeholder is %s.

local Strings = {}

Strings.languages = { "en", "ru" }

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
	["hud.strength"] = "🏆 Strength: %s",
	["hud.rankBonus"] = "+%s%%",
	["hud.combo"] = "⚡ Pump +%s%%",
	["hud.next"] = "Next: %s — muscles %s, ❤ %s",
	["hud.maxRank"] = "Max rank!",
	["hud.rankUp"] = "⬆ Rank up",
	["hud.tapHint"] = "Tap the screen to do a rep",
	["hud.runHint"] = "Running builds ❤ stamina",
	["hud.autoOn"] = "Auto: on",
	["hud.autoOff"] = "Auto: off",
	["hud.leave"] = "Leave (Q)",
	["hud.lb"] = "lb",
	["hud.weightTitle"] = "%s · %s lb · ❤ −%s per rep",
	["hud.recommended"] = "Recommended: %s %s  (you have %s)",
	["hud.cardioTitle"] = "%s · %s mph · +%s ❤ per sec",
	["hud.speed"] = "%s mph",
	["hud.speedLocked"] = "🔒 %s · ❤%s",
	["hud.poseTitle"] = "🌟 You're on stage! Poses change by themselves",
	["hud.poseInfo"] = "Crowd: +%s ⭐ every %s s · players applaud (F): +%s ⭐",
	["hud.poseHint"] = "More strength, louder crowd",
	["hud.maxPlates"] = "Max %s plates",
	["hud.minPlates"] = "You need at least one plate",
	["hud.lang"] = "🌐 EN",

	-- Popups and tags
	["popup.perfect"] = "Perfect weight!",
	["tag.locked"] = "🔒 Strength %s",
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
	["n.locked"] = "🔒 Unlocks at %s Strength",
	["n.onStage"] = "You're on stage! The crowd gives ⭐ Fame, players can applaud",
	["n.tooHeavy"] = "Too heavy! Need %s, you have %s",
	["n.noStamina"] = "Out of stamina! Rest or run on the treadmill",
	["n.tooFast"] = "Too fast — speed lowered",
	["n.plates"] = "You can use 1 to %s plates",
	["n.needStamina"] = "Need %s stamina",
	["n.rankUp"] = "New rank: %s! Bonus +%s%%",
	["n.loadFail"] = "Couldn't load your progress — it won't be saved this session",
	["n.leaveFirst"] = "Leave the machine first",
	["n.alreadyApplauded"] = "You already applauded this performance",
	["n.applauded"] = "%s applauds you! +%s ⭐",

	-- NPC speech
	["npc.hello"] = "Hi, %s! Welcome to Neon Gym!",
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

	["hud.strength"] = "🏆 Сила: %s",
	["hud.rankBonus"] = "+%s%%",
	["hud.combo"] = "⚡ Пампинг +%s%%",
	["hud.next"] = "След.: %s — мышцы %s, ❤ %s",
	["hud.maxRank"] = "Максимальный ранг!",
	["hud.rankUp"] = "⬆ Повысить ранг",
	["hud.tapHint"] = "Тапай по экрану — повтор",
	["hud.runHint"] = "Бег качает ❤ выносливость",
	["hud.autoOn"] = "Авто: вкл",
	["hud.autoOff"] = "Авто: выкл",
	["hud.leave"] = "Выйти (Q)",
	["hud.lb"] = "фунт.",
	["hud.weightTitle"] = "%s · %s фунт. · ❤ −%s за повтор",
	["hud.recommended"] = "Рекомендуется: %s %s  (у тебя %s)",
	["hud.cardioTitle"] = "%s · %s миль/ч · +%s ❤ в сек.",
	["hud.speed"] = "%s миль/ч",
	["hud.speedLocked"] = "🔒 %s · ❤%s",
	["hud.poseTitle"] = "🌟 Ты на подиуме! Позы меняются сами",
	["hud.poseInfo"] = "Зрители: +%s ⭐ каждые %s с · игроки аплодируют (F): +%s ⭐",
	["hud.poseHint"] = "Больше Силы — громче зал",
	["hud.maxPlates"] = "Максимум блинов — %s",
	["hud.minPlates"] = "Нужен хотя бы один блин",
	["hud.lang"] = "🌐 RU",

	["popup.perfect"] = "Идеальный вес!",
	["tag.locked"] = "🔒 Сила %s",
	["tag.busy"] = "Занято",
	["tag.free"] = "Свободно — покажи мышцы!",

	["prompt.train"] = "Тренироваться",
	["prompt.start"] = "Начать",
	["prompt.pose"] = "Выйти на подиум",
	["prompt.applaud"] = "Аплодировать 👏",

	["n.taken"] = "Тренажёр занят, найди свободный",
	["n.stageTaken"] = "Это место на подиуме занято",
	["n.locked"] = "🔒 Откроется при Силе %s",
	["n.onStage"] = "Ты на подиуме! Зрители дают ⭐ Славу, игроки могут аплодировать",
	["n.tooHeavy"] = "Слишком тяжело! Нужно %s, у тебя %s",
	["n.noStamina"] = "Нет выносливости! Отдохни или побегай на дорожке",
	["n.tooFast"] = "Слишком быстро — скорость снижена",
	["n.plates"] = "Можно от 1 до %s блинов",
	["n.needStamina"] = "Нужно %s выносливости",
	["n.rankUp"] = "Новый ранг: %s! Бонус +%s%%",
	["n.loadFail"] = "Не удалось загрузить прогресс — он не будет сохранён в этой сессии",
	["n.leaveFirst"] = "Сначала сойди с тренажёра",
	["n.alreadyApplauded"] = "Ты уже аплодировал этому выходу",
	["n.applauded"] = "%s аплодирует тебе! +%s ⭐",

	["npc.hello"] = "Привет, %s! Добро пожаловать в Neon Gym!",
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

function Strings.t(lang, key, ...)
	local dict = Strings[lang] or Strings.en
	local s = dict[key] or Strings.en[key] or key
	if select("#", ...) > 0 then
		local ok, result = pcall(string.format, s, ...)
		return ok and result or s
	end
	return s
end

-- Default language from a Roblox locale id like "ru-ru" or "en-us"
function Strings.fromLocale(localeId)
	localeId = string.lower(localeId or "")
	if string.sub(localeId, 1, 2) == "ru" then
		return "ru"
	end
	return "en"
end

function Strings.next(lang)
	return lang == "en" and "ru" or "en"
end

return Strings
