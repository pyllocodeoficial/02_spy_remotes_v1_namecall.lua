-- 02: Spy v1 - intercepta FireServer/InvokeServer via __namecall
-- (so de remotes dentro de uma pasta chamada "Remotes") e escuta
-- eventos do servidor (Throw_MeterStarted, Throw_Revealed, Training_Bonus).
-- Limitacao: nao mostra o retorno das RemoteFunction.

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local lines = {}
local box

local function add(s)
	table.insert(lines, s)
	if #lines > 60 then table.remove(lines, 1) end
	if box then box.Text = table.concat(lines, "\n") end
end

local function fmt(v, d)
	d = d or 0
	if typeof(v) == "table" and d < 2 then
		local t = {}
		for k, x in pairs(v) do table.insert(t, tostring(k) .. "=" .. fmt(x, d + 1)) end
		return "{" .. table.concat(t, ", ") .. "}"
	end
	return typeof(v) .. ":" .. tostring(v)
end

local gui = Instance.new("ScreenGui")
gui.Name = "SpyRemotes"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

box = Instance.new("TextBox")
box.Size = UDim2.new(0, 320, 0, 220)
box.Position = UDim2.new(0.5, -160, 0.5, -110)
box.BackgroundColor3 = Color3.new(0, 0, 0)
box.BackgroundTransparency = 0.2
box.TextColor3 = Color3.new(1, 1, 1)
box.Font = Enum.Font.Code
box.TextSize = 12
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.TextWrapped = true
box.MultiLine = true
box.ClearTextOnFocus = false
box.TextEditable = false
box.Text = "Faca: treinar, arremessar, vender.\nAs chamadas aparecem aqui."
box.Parent = gui

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 60, 0, 22)
close.Position = UDim2.new(0.5, 100, 0.5, -136)
close.Text = "Fechar"
close.BackgroundColor3 = Color3.fromRGB(190, 55, 55)
close.TextColor3 = Color3.new(1, 1, 1)
close.Parent = gui
close.Activated:Connect(function() gui:Destroy() end)

-- Spy das chamadas ao servidor
local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
	local m = getnamecallmethod()
	if (m == "InvokeServer" or m == "FireServer") and typeof(self) == "Instance"
		and self.Parent and self.Parent.Name == "Remotes" then
		local args = table.pack(...)
		local t = {}
		for i = 1, args.n do t[i] = fmt(args[i]) end
		task.defer(add, "[" .. self.Name .. "] " .. table.concat(t, ", "))
	end
	return old(self, ...)
end)
setreadonly(mt, true)

-- Eventos que o servidor manda
local R = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 10)
for _, n in ipairs({"Throw_MeterStarted", "Throw_Revealed", "Training_Bonus"}) do
	local e = R and R:FindFirstChild(n)
	if e then
		e.OnClientEvent:Connect(function(...)
			local t = {}
			for i, a in ipairs({...}) do t[i] = fmt(a) end
			add("<< " .. n .. ": " .. table.concat(t, ", "))
		end)
	end

end
