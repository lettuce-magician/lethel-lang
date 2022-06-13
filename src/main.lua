local parser = require "parser"

if arg[1] == nil then
    print("lowLethel v0.1")
    print("very funny language")
    while true do
        io.write(">>> ")
        local text = io.read()
        local ok, err = pcall(parser, text)
        if not ok then
            print(err)
        end
    end
else
    local f = io.open(arg[1], "r")
    if f ~= nil then
        local text = f:read("*a")
        f:close()
        local ok, err = pcall(parser, text)
        if not ok then
            print(err)
        end
    else
        print("file not found")
    end
end