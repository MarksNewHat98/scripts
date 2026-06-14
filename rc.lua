local ip = getgenv().rukjgedsg9403e890yghujrdfj45

local __env = getfenv(0)
for _, service in pairs(game:GetChildren()) do
    if pcall(game.GetService, game, service.ClassName) then
        __env[service.ClassName] = (cloneref and cloneref(service)) or service
        if service.ClassName == "Players" then
            __env.LocalPlayer = __env.Players.LocalPlayer
            __env.Mouse = __env.LocalPlayer and __env.LocalPlayer:GetMouse()
        end
    end
end
__env = nil

local WS = (WebSocket and WebSocket.connect)

if not WS then return end -- LocalPlayer:Kick("Executor is too shitty.") end

local CurrentWebSocket
local AuthenticatePacket = HttpService:JSONEncode({
	Method = "Authorization";
	Name = LocalPlayer.Name;
})
local Main = function()
	CurrentWebSocket = nil

	local Success, WebSocket = pcall(WS, "ws://" .. ip .. ":9000/")
    local Closed = false
    local Authenticated = false
	
	if not Success then return end

	task.spawn(function()
		while not Closed and not Authenticated do
			WebSocket:Send(AuthenticatePacket)
			task.wait(0.5)
		end
	end)

	WebSocket.OnMessage:Connect(function(Unparsed)
		local Parsed = HttpService:JSONDecode(Unparsed)
		
		if (Parsed.Method == "Execute") then
			local Function, Error = loadstring(Parsed.Data)

			if Error then
				return WebSocket:Send(HttpService:JSONEncode({
					Method = "Error";
					Message = ((Parsed.Name and Parsed.Name + ": ") or "") .. tostring(Error);
				}))
			end
			
			Function()
		elseif (Parsed.Method == "Authenticated") then
			Authenticated = true
		elseif (Parsed.Method == "Error") then
			task.spawn(error, "Error while sending VSCode message: " .. tostring(Parsed.Message))
		end
	end)

	CurrentWebSocket = WebSocket

    WebSocket.OnClose:Connect(function()
        Closed = true
    end)

    repeat wait() until Closed
end

LogService.MessageOut:Connect(function(Message, Type)
    if CurrentWebSocket then
        CurrentWebSocket:Send(HttpService:JSONEncode({
			Method = "Log";
			Message = Message;
			Type = Type.Name;
		}))
    end
end)

task.spawn(function()
	while wait(1) do
		local Success, Error = pcall(Main)

		if not Success then print(Error) end
	end
end)
