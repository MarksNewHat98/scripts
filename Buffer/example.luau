local Buffer = require(script.Buffer)

local buffBuild = Buffer.new()
	:createValue("string", "stringa")
	:createValue("bool8", "bitbool")
	:createValue("f32", "floatie")
	:createValue("i8", "very limited")
	:createValue("i8", "ohnowraparound")
	:createValue("cframe_lossless", "a lot of numbers")

local buff = buffBuild:build({
	bitbool = {true, nil, false, nil, true, nil, false, nil},
	stringa = "hello im a stringer",
	floatie = math.pi,
	["very limited"] = 127,
	ohnowraparound = 128,
	["a lot of numbers"] = { CFrame.new(35, 259, math.pi) },
})

print(buff, buffer.len(buff))

print("bitbool:", buffBuild:read(buff, "bitbool"))
print("stringa:", buffBuild:read(buff, "stringa"))
print("floatie:", buffBuild:read(buff, "floatie"))
print("very limited:", buffBuild:read(buff, "very limited"))
print("ohnowraparound:", buffBuild:read(buff, "ohnowraparound"))
print("a lot of numbers:", buffBuild:read(buff, "a lot of numbers"))
