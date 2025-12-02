repeat
	task.wait()
until game:IsLoaded()

local HUB_SCRIPT_ID = "9b5ab79f8007e89b695dac53c55f0904"
local HUB_DISCORD_CODE = "mAmR6kz3QH"
local HUB_KEY_LINK = "https://ads.luarmor.net/get_key?for=BoatBuilderHub_Key_System-FxZfyDCbapNR"

local KEY_FOLDER = "BBuilderHub"
local KEY_FILE = KEY_FOLDER .. "/Key.txt"
local OLD_KEY_FILE = KEY_FOLDER .. "/Settings.config"

local PlaceIDs = {
	["537413528"] = "9b5ab79f8007e89b695dac53c55f0904",
	["76558904092080"] = "0bef79fe69ee3fe8607ff9f07f2d8def",
}

local Names = {
	["537413528"] = "BoatBuilderHub",
	["76558904092080"] = "ReForge",
}
local HUB_NAME = Names[tostring(game.PlaceId)] or "BuilderHub"

local ReGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/depthso/Dear-ReGui/main/ReGui.lua"))()
local luarmor = loadstring(game:HttpGet("https://sdkapi-public.luarmor.net/library.lua"))()

local cloneref = cloneref or function(x)
	return x
end
local Players = cloneref(game:GetService("Players"))
local AssetService = cloneref(game:GetService("AssetService"))
local HttpService = cloneref(game:GetService("HttpService"))
local Request = http_request or request or syn and syn.request or http

local function norm(s)
	if not s then
		return nil
	end
	local t = tostring(s):gsub("%s+", "")
	if t == "" then
		return nil
	end
	return t
end

local function ensureFolder()
	if not isfolder(KEY_FOLDER) then
		makefolder(KEY_FOLDER)
	end
end

local function readKey()
	if not isfile(KEY_FILE) then
		return nil
	end
	local ok, v = pcall(readfile, KEY_FILE)
	return ok and norm(v) or nil
end

local function writeKey(k)
	k = norm(k)
	if not k then
		return
	end
	ensureFolder()
	if isfile(OLD_KEY_FILE) then
		pcall(delfile, OLD_KEY_FILE)
	end
	pcall(writefile, KEY_FILE, k)
end

local function migrateOld()
	if isfile(OLD_KEY_FILE) then
		local ok, v = pcall(readfile, OLD_KEY_FILE)
		if ok then
			_G.script_key = norm(v) or _G.script_key
		end
		pcall(delfile, OLD_KEY_FILE)
	end
end

local function clearKey()
	if isfile(KEY_FILE) then
		pcall(delfile, KEY_FILE)
	end
	_G.script_key = nil
end

ensureFolder()
migrateOld()
_G.script_key = _G.script_key or readKey()

luarmor.script_id = HUB_SCRIPT_ID
do
	local ok, pages = pcall(function()
		return AssetService:GetGamePlacesAsync()
	end)
	if ok and pages then
		local cur = pages:GetCurrentPage()
		while true do
			for _, place in ipairs(cur) do
				local sid = PlaceIDs[tostring(place.PlaceId)]
				if sid then
					luarmor.script_id = sid
					break
				end
			end
			if pages.IsFinished then
				break
			end
			pages:AdvanceToNextPageAsync()
			cur = pages:GetCurrentPage()
		end
	end
end
luarmor.script_id = PlaceIDs[tostring(game.PlaceId)] or luarmor.script_id

if not PlaceIDs[tostring(game.PlaceId)] then
	game.Players.LocalPlayer:Kick("Game not supported for this script.")
end

local function validate(k)
	k = norm(k)
	if not k then
		return false, { code = "KEY_INVALID", message = "missing" }
	end
	_G.script_key = k
	local ok, status = pcall(function()
		return luarmor.check_key(k)
	end)
	if not ok then
		return false, { code = "CHECK_FAILED", message = tostring(status) }
	end
	if status and status.code == "KEY_VALID" then
		writeKey(k)
		return true, status
	end
	return false, status
end

local function instcheck()
	local k = norm(_G.script_key) or readKey()
	if not k then
		return false
	end
	local ok, status = validate(k)
	if ok then
		luarmor.load_script()
		return true
	end
	if status and status.code and status.code:find("KEY_") then
		clearKey()
	end
	return false
end

if instcheck() then
	return
end

local win = ReGui:Window({
	Title = HUB_NAME .. " | Key System",
	NoClose = true,
	NoResize = true,
	Size = UDim2.new(0, 400, 0, 280),
}):Center()
local statusLabel = win:Label({ Text = "", TextWrapped = true, TextColor3 = Color3.fromRGB(255, 40, 40) })

local function setStatus(t, good)
	statusLabel.Text = t
	statusLabel.TextColor3 = good and Color3.fromRGB(40, 255, 40) or Color3.fromRGB(255, 40, 40)
end

win:Label({ Text = "🔒 Script Locked", TextScaled = false, TextSize = 20, Size = UDim2.new(1, 0, 0, 30) })
win:Separator()
win:Label({ Text = "Enter your key to continue:", TextWrapped = true })

local keyText = _G.script_key or ""
win:InputText({
	Label = "Key",
	Placeholder = "Paste key here",
	Default = keyText,
	Callback = function(_, v)
		keyText = v
	end,
})

local rowA = win:Row({ Expanded = true })
rowA:Button({
	Text = "Get Key",
	BackgroundColor3 = Color3.fromRGB(255, 165, 30),
	Callback = function()
		setclipboard(HUB_KEY_LINK)
		setStatus("Key link copied", true)
	end,
})

rowA:Button({
	Text = "Submit",
	BackgroundColor3 = Color3.fromRGB(70, 200, 120),
	Callback = function()
		local ok, status = validate(keyText)
		if ok then
			setStatus("Key valid, loading...", true)
			task.delay(0.35, function()
				pcall(function()
					win:Close()
				end)
			end)
			luarmor.load_script()
		else
			if status and status.code and status.code:find("KEY_") then
				clearKey()
				local m = {
					KEY_HWID_LOCKED = "Key locked to another HWID",
					KEY_INCORRECT = "Incorrect key",
					KEY_INVALID = "Invalid key",
				}
				setStatus(m[status.code] or "Key check failed", false)
			else
				Players.LocalPlayer:Kick("Key check failed: " .. tostring(status and status.message or "Unknown"))
			end
		end
	end,
})

local rowB = win:Row({ Expanded = true })
rowB:Button({
	Text = "Join Discord",
	BackgroundColor3 = Color3.fromRGB(255, 80, 80),
	Callback = function()
		setclipboard("https://discord.gg/" .. HUB_DISCORD_CODE)
		setStatus("discord.gg/" .. HUB_DISCORD_CODE .. " copied", true)
		if Request then
			Request({
				Url = "http://127.0.0.1:6463/rpc?v=1",
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json", ["origin"] = "https://discord.com" },
				Body = HttpService:JSONEncode({ args = { code = HUB_DISCORD_CODE }, cmd = "INVITE_BROWSER", nonce = "." }),
			})
		end
	end,
})

rowB:Button({
	Text = "Help",
	BackgroundColor3 = Color3.fromRGB(30, 200, 200),
	Callback = function()
		local p = win:PopupModal({ Title = "Help", AutoSize = "Y", Visible = true })
		p:Label({
			Text = "1. Press Get Key and open the link.\n2. Finish steps and copy the key.\n3. Paste and Submit.",
			TextWrapped = true,
		})
		p:Separator()
		p:Button({
			Text = "Close",
			Callback = function()
				p:ClosePopup()
			end,
		})
	end,
})
