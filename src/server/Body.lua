-- Overhead tag (name, Сила, rank) and body growth with Сила.
-- Body growth uses R15 scale values; on R6 avatars it is skipped.

local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)

local Body = {}

local function getTag(character)
	local head = character:FindFirstChild("Head")
	if not head then
		return nil
	end
	local tag = head:FindFirstChild("NeonTag")
	if tag then
		return tag
	end

	tag = Instance.new("BillboardGui")
	tag.Name = "NeonTag"
	tag.Size = UDim2.fromOffset(220, 66)
	tag.StudsOffset = Vector3.new(0, 2.8, 0)
	tag.MaxDistance = 90
	tag.AlwaysOnTop = false
	tag.Parent = head

	local function line(name, y, h, color, font)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromScale(0, y)
		l.Size = UDim2.fromScale(1, h)
		l.TextScaled = true
		l.Font = font
		l.TextColor3 = color
		l.TextStrokeTransparency = 0.3
		l.Parent = tag
		return l
	end
	line("Sila", 0, 0.32, Color3.fromRGB(255, 220, 90), Enum.Font.GothamBlack)
	line("Rank", 0.32, 0.26, Color3.fromRGB(200, 170, 255), Enum.Font.GothamBold)
	line("PlayerName", 0.58, 0.42, Color3.new(1, 1, 1), Enum.Font.GothamBlack)
	return tag
end

function Body.update(player, profile)
	local character = player.Character
	if not character then
		return
	end

	local sila = Config.sila(profile.stats)
	local tag = getTag(character)
	if tag then
		tag.Sila.Text = "🏆 " .. Config.format(sila)
		tag.Rank.Text = Config.Ranks[profile.rank].title
		tag.PlayerName.Text = player.DisplayName
	end

	-- Hide the default name so the tag isn't doubled
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	-- Wider and deeper body as Сила grows (1.0 -> 1.6). Height stays the same,
	-- so machine seat positions still fit.
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		local growth = math.clamp(math.log10(sila + 1) / 7, 0, 1)
		local scale = 1 + 0.6 * growth
		for _, name in ipairs({ "BodyWidthScale", "BodyDepthScale" }) do
			local value = humanoid:FindFirstChild(name)
			if value and math.abs(value.Value - scale) > 0.02 then
				value.Value = scale
			end
		end
	end
end

return Body
