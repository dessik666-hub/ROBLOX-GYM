-- HUD: stat bar (top), Сила/rank/stamina (left), plate or speed selector (bottom), toasts.
-- Built in code; sizes use scale where it matters so it works on phones.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(RS:WaitForChild("Shared"):WaitForChild("Config"))

local Hud = {}

local BG = Color3.fromRGB(20, 12, 36)
local CARD = Color3.fromRGB(45, 28, 75)
local CARD_LOCKED = Color3.fromRGB(30, 26, 40)
local ACCENT = Color3.fromRGB(255, 80, 200)
local GOOD = Color3.fromRGB(90, 240, 140)
local BAD = Color3.fromRGB(255, 80, 90)

local refs = {}
local callbacks = {}

---------------------------------------------------------------------------
-- Small builders
---------------------------------------------------------------------------
local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local function corner(parent, r)
	new("UICorner", { CornerRadius = UDim.new(0, r or 10) }, parent)
end

local function stroke(parent, color, thickness)
	return new("UIStroke", { Color = color, Thickness = thickness or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent)
end

local function label(parent, props)
	local l = new("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
	}, parent)
	for k, v in pairs(props) do
		l[k] = v
	end
	return l
end

local function button(parent, props, onClick)
	local b = new("TextButton", {
		BackgroundColor3 = CARD,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		AutoButtonColor = true,
	}, parent)
	for k, v in pairs(props) do
		b[k] = v
	end
	corner(b, 8)
	b.MouseButton1Click:Connect(onClick)
	return b
end

local function maxText(parent, size)
	new("UITextSizeConstraint", { MaxTextSize = size }, parent)
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------
function Hud.build(cb)
	callbacks = cb
	local gui = new("ScreenGui", { Name = "NeonGymHUD", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, Players.LocalPlayer:WaitForChild("PlayerGui"))
	refs.gui = gui

	-- Top stat bar (6 chips, like the video)
	local top = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.new(0.66, 0, 0, 50),
		BackgroundTransparency = 1,
	}, gui)
	new("UISizeConstraint", { MaxSize = Vector2.new(760, 50) }, top)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 4) }, top)
	refs.chips = {}
	for i, s in ipairs(Config.Stats) do
		local chip = new("Frame", { Size = UDim2.new(1 / 6, -4, 1, 0), BackgroundColor3 = BG, BackgroundTransparency = 0.25, LayoutOrder = i }, top)
		corner(chip, 10)
		stroke(chip, s.color, 1.5)
		local value = label(chip, { Size = UDim2.fromScale(1, 0.62), Text = s.icon .. " 0", TextColor3 = s.color, Font = Enum.Font.GothamBlack })
		maxText(value, 20)
		local name = label(chip, { Position = UDim2.fromScale(0, 0.6), Size = UDim2.fromScale(1, 0.36), Text = s.name, TextColor3 = Color3.fromRGB(210, 200, 230) })
		maxText(name, 12)
		refs.chips[s.key] = value
	end

	-- Left panel: Сила, rank, stamina, combo, rank-up
	local left = new("Frame", { Position = UDim2.new(0, 10, 0, 64), Size = UDim2.fromOffset(250, 150), BackgroundColor3 = BG, BackgroundTransparency = 0.25 }, gui)
	corner(left, 12)
	stroke(left, ACCENT, 1.5)
	new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 6) }, left)
	refs.sila = label(left, { Size = UDim2.new(1, 0, 0, 30), Text = "🏆 Сила: 0", TextColor3 = Color3.fromRGB(255, 220, 90), Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left })
	refs.rank = label(left, { Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 18), Text = "Новичок", TextColor3 = Color3.fromRGB(200, 170, 255), TextXAlignment = Enum.TextXAlignment.Left })
	local energyBack = new("Frame", { Position = UDim2.fromOffset(0, 54), Size = UDim2.new(1, 0, 0, 20), BackgroundColor3 = Color3.fromRGB(50, 20, 35) }, left)
	corner(energyBack, 10)
	refs.energyFill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 70, 110) }, energyBack)
	corner(refs.energyFill, 10)
	refs.energyText = label(energyBack, { Size = UDim2.fromScale(1, 1), Text = "❤ 50 / 50", ZIndex = 2 })
	maxText(refs.energyText, 14)
	refs.combo = label(left, { Position = UDim2.fromOffset(0, 78), Size = UDim2.new(1, 0, 0, 20), Text = "", TextColor3 = Color3.fromRGB(255, 230, 120), TextXAlignment = Enum.TextXAlignment.Left })
	refs.nextRank = label(left, { Position = UDim2.fromOffset(0, 100), Size = UDim2.new(1, 0, 0, 14), Text = "", TextColor3 = Color3.fromRGB(170, 160, 200), Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left })
	refs.rankUp = button(left, { Position = UDim2.fromOffset(0, 116), Size = UDim2.new(1, 0, 0, 26), Text = "⬆ Повысить ранг", BackgroundColor3 = Color3.fromRGB(40, 170, 90), Visible = false }, function()
		callbacks.rankUp()
	end)

	-- Toast
	refs.toast = label(gui, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.2, 0),
		Size = UDim2.new(0.8, 0, 0, 34),
		Text = "",
		TextStrokeTransparency = 0.3,
		Font = Enum.Font.GothamBlack,
	})
	maxText(refs.toast, 28)

	-- Bottom training panel
	local panel = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(0.94, 0, 0, 178),
		BackgroundTransparency = 1,
		Visible = false,
	}, gui)
	new("UISizeConstraint", { MaxSize = Vector2.new(820, 178) }, panel)
	refs.panel = panel

	refs.title = label(panel, { Size = UDim2.new(1, 0, 0, 30), Text = "", Font = Enum.Font.GothamBlack, TextStrokeTransparency = 0.4 })
	refs.rec = label(panel, { Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 22), Text = "", TextStrokeTransparency = 0.4 })
	maxText(refs.rec, 20)

	-- Plate row
	refs.plateRow = new("Frame", { Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 0, 82), BackgroundTransparency = 1 }, panel)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6) }, refs.plateRow)
	refs.plates = {}
	for i, plate in ipairs(Config.Plates) do
		local card = new("Frame", { Size = UDim2.new(1 / 6, -6, 1, 0), BackgroundColor3 = BG, BackgroundTransparency = 0.15, LayoutOrder = i }, refs.plateRow)
		corner(card, 10)
		local cardStroke = stroke(card, Color3.fromRGB(90, 70, 130), 1.5)
		button(card, { Position = UDim2.fromScale(0.03, 0.04), Size = UDim2.fromScale(0.28, 0.3), Text = "−" }, function()
			callbacks.plate(i, -1)
		end)
		local count = label(card, { Position = UDim2.fromScale(0.33, 0.04), Size = UDim2.fromScale(0.34, 0.3), Text = "x0", Font = Enum.Font.GothamBlack })
		button(card, { Position = UDim2.fromScale(0.69, 0.04), Size = UDim2.fromScale(0.28, 0.3), Text = "+" }, function()
			callbacks.plate(i, 1)
		end)
		local disc = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.38), Size = UDim2.fromScale(0.34, 0.34), BackgroundColor3 = plate.color }, card)
		new("UIAspectRatioConstraint", { AspectRatio = 1 }, disc)
		corner(disc, 100)
		stroke(disc, Color3.fromRGB(230, 230, 240), 1)
		local w = label(card, { Position = UDim2.fromScale(0, 0.74), Size = UDim2.fromScale(1, 0.24), Text = plate.weight .. " фунт.", TextColor3 = Color3.fromRGB(220, 210, 240) })
		maxText(w, 14)
		refs.plates[i] = { count = count, stroke = cardStroke }
	end

	-- Speed row (cardio)
	refs.speedRow = new("Frame", { Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 0, 82), BackgroundTransparency = 1, Visible = false }, panel)
	new("UIGridLayout", { CellSize = UDim2.new(0.2, -6, 0.5, -4), CellPadding = UDim2.fromOffset(6, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center }, refs.speedRow)
	refs.speeds = {}
	for i, sp in ipairs(Config.Speeds) do
		refs.speeds[i] = button(refs.speedRow, { Text = sp.mph .. " миль/ч", LayoutOrder = i }, function()
			callbacks.speed(i)
		end)
		maxText(refs.speeds[i], 16)
	end

	-- Controls
	local controls = new("Frame", { Position = UDim2.fromOffset(0, 144), Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1 }, panel)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center }, controls)
	refs.hint = label(controls, { Size = UDim2.new(0.42, 0, 1, 0), Text = "Тапай по экрану — повтор", TextColor3 = Color3.fromRGB(200, 190, 230), LayoutOrder = 1 })
	maxText(refs.hint, 16)
	refs.auto = button(controls, { Size = UDim2.new(0.25, 0, 1, 0), Text = "Авто: выкл", LayoutOrder = 2 }, function()
		callbacks.auto()
	end)
	maxText(refs.auto, 16)
	local exit = button(controls, { Size = UDim2.new(0.25, 0, 1, 0), Text = "Выйти (Q)", BackgroundColor3 = Color3.fromRGB(170, 40, 70), LayoutOrder = 3 }, function()
		callbacks.leave()
	end)
	maxText(exit, 16)
end

---------------------------------------------------------------------------
-- Update from server state (plus local pending plates)
---------------------------------------------------------------------------
function Hud.update(state, plates)
	local stats = state.stats

	for _, s in ipairs(Config.Stats) do
		refs.chips[s.key].Text = s.icon .. " " .. Config.format(stats[s.key])
	end

	refs.sila.Text = "🏆 Сила: " .. Config.format(Config.sila(stats))
	local rank = Config.Ranks[state.rank]
	refs.rank.Text = rank.title
		.. (rank.bonus > 0 and ("  ·  +" .. math.floor(rank.bonus * 100 + 0.5) .. "%") or "")
		.. "  ·  ⭐ " .. Config.format(state.fame or 0)

	local ratio = state.energyMax > 0 and math.clamp(state.energy / state.energyMax, 0, 1) or 0
	refs.energyFill.Size = UDim2.fromScale(ratio, 1)
	refs.energyText.Text = "❤ " .. Config.format(state.energy) .. " / " .. Config.format(state.energyMax)

	refs.combo.Text = state.combo > 0 and ("⚡ Пампинг +" .. math.floor(state.combo * 100 + 0.5) .. "%") or ""

	local nextRank = Config.Ranks[state.rank + 1]
	if nextRank then
		refs.nextRank.Text = "След.: " .. nextRank.title .. " — мышцы " .. Config.format(nextRank.muscle) .. ", ❤ " .. Config.format(nextRank.stamina)
	else
		refs.nextRank.Text = "Максимальный ранг!"
	end
	refs.rankUp.Visible = Config.canRankUp(stats, state.rank)

	-- Training panel
	local machine = state.kind and Config.Machines[state.kind]
	refs.panel.Visible = machine ~= nil
	if not machine then
		return
	end

	if machine.type == "pose" then
		refs.plateRow.Visible = false
		refs.speedRow.Visible = false
		refs.auto.Visible = false
		refs.title.Text = "🌟 Ты на подиуме! Позы меняются сами"
		local perTick = math.floor(Config.crowdFame(Config.sila(stats)) * (1 + rank.bonus))
		refs.rec.Text = "Зрители: +" .. perTick .. " ⭐ каждые " .. Config.CrowdInterval .. " с · игроки аплодируют (F): +" .. Config.ApplauseFame .. " ⭐"
		refs.rec.TextColor3 = Color3.fromRGB(255, 220, 120)
		refs.hint.Text = "Больше Силы — громче зал"
		return
	end

	local stat = machine.stat == "all" and { icon = "🔥", name = "все мышцы" } or Config.StatByKey[machine.stat]
	local have = Config.machineStat(stats, machine)

	if machine.type == "weights" then
		refs.plateRow.Visible = true
		refs.speedRow.Visible = false
		refs.hint.Text = "Тапай по экрану — повтор"
		refs.auto.Visible = true
		refs.auto.Text = state.auto and "Авто: вкл" or "Авто: выкл"
		refs.auto.BackgroundColor3 = state.auto and Color3.fromRGB(40, 170, 90) or CARD

		local weight = Config.totalWeight(plates)
		local req = Config.requirement(weight)
		refs.title.Text = machine.name .. " · " .. weight .. " фунт. · ❤ −" .. Config.repCost(weight) .. " за повтор"
		refs.rec.Text = "Рекомендуется: " .. stat.icon .. " " .. Config.format(req) .. "  (у тебя " .. Config.format(have) .. ")"
		refs.rec.TextColor3 = have >= req and GOOD or BAD
		for i, r in ipairs(refs.plates) do
			local n = plates[i] or 0
			r.count.Text = "x" .. n
			r.stroke.Color = n > 0 and ACCENT or Color3.fromRGB(90, 70, 130)
		end
	else
		refs.plateRow.Visible = false
		refs.speedRow.Visible = true
		refs.hint.Text = "Бег качает ❤ выносливость"
		refs.auto.Visible = false

		local sp = Config.Speeds[state.speed]
		local gain = sp.gain * machine.mult * (1 + rank.bonus)
		refs.title.Text = machine.name .. " · " .. sp.mph .. " миль/ч · +" .. Config.format(gain) .. " ❤ в сек."
		refs.rec.Text = "Рекомендуется: ❤ " .. Config.format(sp.req) .. "  (у тебя " .. Config.format(stats.stamina) .. ")"
		refs.rec.TextColor3 = stats.stamina >= sp.req and GOOD or BAD
		for i, b in ipairs(refs.speeds) do
			local s = Config.Speeds[i]
			local locked = stats.stamina < s.req
			if i == state.speed then
				b.BackgroundColor3 = Color3.fromRGB(40, 170, 90)
			else
				b.BackgroundColor3 = locked and CARD_LOCKED or CARD
			end
			b.Text = locked and ("🔒 " .. s.mph .. " · ❤" .. Config.format(s.req)) or (s.mph .. " миль/ч")
		end
	end
end

---------------------------------------------------------------------------
-- Toasts
---------------------------------------------------------------------------
local toastToken = 0
function Hud.toast(text, kind)
	toastToken += 1
	local my = toastToken
	local t = refs.toast
	t.Text = text
	t.TextColor3 = kind == "warn" and BAD or kind == "good" and GOOD or Color3.new(1, 1, 1)
	t.TextTransparency = 0
	t.TextStrokeTransparency = 0.3
	task.delay(2.2, function()
		if toastToken == my then
			TweenService:Create(t, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

return Hud
