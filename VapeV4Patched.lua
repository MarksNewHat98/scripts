local function findfuncupvalue(tvalue, func)
    local success, index, value = pcall(function()
	    local index, value = 1, 234
        while value do
            value = debug.getupvalue(func, index)
            if (type(tvalue) == "function" and tvalue(index, value)) or value == tvalue then
                return index, value
            end

            index = index + 1
        end
    end)
    if success then
        return index, value
    end
end

loadstring(game:HttpGet("https://github.com/MarksNewHat98/scripts/raw/refs/heads/main/LoadstringPatcherSrc.lua", true))(getfenv and getfenv() or _ENV, {
    -- vape whitelist patch
    [{ "universal", "(local run = function%(func%)\n	)func%(%)(\nend)", "%1[INJECTED_FUNCTION](func)%2" }] = function(func)
        local i, v = findfuncupvalue(function(i, v)
            if
                type(v) == "table" and
                rawget(v, "customtags") and rawget(v, "hooked") == false and rawget(v, "alreadychecked") and
                rawget(v, "loaded") == false and rawget(v, "data") and rawget(v, "tagcallback") and
                rawget(v, "said") and rawget(v, "localprio") and rawget(v, "hashes")
            then
                return true
            end
            return
        end, func)

        func()

        if i and v.get then
            local nop = function() end
            v.hook = nop
            v.playeradded = nop
            v.process = nop
            --[[function v:get()
                return 0, false
            end--]]
        end
    end,

    -- vape queue_on_teleport patch
    [{ "main", "(vape:Clean%(playersService.LocalPlayer.OnTeleport:Connect%(function%(%))" }] = "%1if true then return end;",
})

loadstring(game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/NewMainScript.lua", true))()
