-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script
-- please use the loadstring inside "LoadstringPatcher.lua" instead of copying this script

local args = {...}
local genv = args[1]
local patches = args[2]

local function mergeTables(target, ...)
    for _, from in pairs({...}) do
        for _, v in pairs(from) do
            table.insert(target, v)
        end
    end

    return target
end

local function numberRange(min, max)
    local tbl = {}
    for i = min, max do
        table.insert(tbl, i)
    end
    return tbl
end

local _randomString_chars = mergeTables({}, numberRange(48, 57), numberRange(65, 90), numberRange(97, 122), {33,35,36,38,39,44,45,46,47,58,59,60,61,62,94,95,96})
local function randomString()
	local str = ""
	for i = 1, 30 do
		str = str .. string.char(_randomString_chars[math.random(1, #_randomString_chars)])
	end
	return str
end

local function fromhex(str)
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end

local function tohex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end))
end

if not table.find then
    function table.find(list, value, start)
        local index = 1
        for i, v in pairs(list) do
            if not start or index >= start then
                if v == value then
                    return i
                end
            end
            
            index = index + 1
        end
    end
end

local _loadstring = genv.loadstring or genv.load
local function loadstring_wrap(code, name, ...)
    for data, value in pairs(patches) do
        local data1, data2, data3 = data[1], data[2], data[3]
        local check = data1 == nil or data1 == name
        if type(data1) == "table" then
            local wltype = data1[1]
            for i, d1name in pairs(data1) do
                if i ~= 1 then
                    if wltype == "whitelist" and d1name == name then
                        check = true
                        break
                    elseif wltype == "blacklist" and d1name ~= name then
                        check = true
                        break
                    end
                end
            end
        end

        if check then
            local replacement
            if type(value) == "function" then
                local func_name = randomString()
                genv[func_name] = value
                replacement = 'getfenv and getfenv() or _ENV["' .. func_name .. '"]'

                if data3 then
                    replacement = string.gsub(data3, "%[INJECTED_FUNCTION%]", replacement)
                end
            else
                replacement = value
            end

            code = string.gsub(code, data2, replacement)
        end
    end

    return _loadstring(code, name, ...)
end

if genv.load then
    genv.load = loadstring_wrap
end
genv.loadstring = loadstring_wrap
