-- uses lua regex: https://gitspartv.github.io/lua-patterns/
loadstring(game:HttpGet("https://github.com/MarksNewHat98/scripts/raw/refs/heads/main/LoadstringPatcherSrc.lua", true))(getfenv(), {
    -- example patches
    [{ "example_code", '(print%(")(this string is unique)("%))'}] = "%1%2%2%3", -- repeats the string "this string is unique" in the print statement
    [{ { "blacklist", "example_code" }, "(print%()'haha cant inject here'(%))", "%1[INJECTED_FUNCTION]%(%)%2" }] = function()
        return "hello we have injected"
    end, -- replaces the print's string with a function
})
-- insert your loadstring script to be patched down here

local example_code = [[print("this string is unique")
print("this string is here")
loadstring("print('haha cant inject here')")()]]
loadstring(example_code, "example_code")()
