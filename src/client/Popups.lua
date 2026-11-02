-- Floating "+N" numbers over a character's head.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Popups = {}

function Popups.show(character, text, color, big)
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(big and 200 or 150, big and 50 or 38)
	gui.StudsOffset = Vector3.new((math.random() - 0.5) * 2.5, 2.5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 80
	gui.Adornee = head
	gui.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextStrokeTransparency = 0.2
	label.Parent = gui

	local info = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(gui, info, { StudsOffset = gui.StudsOffset + Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(gui, 1.2)
end

return Popups
