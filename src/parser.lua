local f = string.format

local lex = require 'lexer'
local keyword = require 'env'.keyword
local logging = require 'logging'

return function (text)
    local lines = lex(text)
    local ignore = {}
    local line = 0
    local token = 0
    local ctoken = {}
    local slib = {}
    local ret = {}

    local function args(argc)
        local arg = {}
        repeat
            if line == 0 then line = 1 end
            token = token + 1
            ctoken = lines[line][token]

            if ctoken == nil then break end

            if ctoken.type == "argsep" or ctoken.type == "comment" then
            elseif ctoken.type == "keyword" or ctoken.type == "newline" or ctoken.type == "eof" then
                break
            elseif (ctoken.type == "ident" or ctoken.type == "operator" or ctoken.type == "bitwise") then
                arg[#arg + 1] = ctoken
            else
                logging.run(f("%s is not eatable for arguments.", ctoken.value), 4)
            end
        until false

        return arg
    end

    slib.marks = {}
    slib.line = 0

    function slib.cline(n)
        line = n-1
        slib.line=line
    end

    function slib.currtoken(i)
        i = i or 0
        return lines[line][token+i]
    end

    function slib.ignore(s, r)
        repeat
            token = token + 1
            if line > #lines then
                logging.run('keep searching boys we still didnt found "'..s..'"', 4)
            end
            ctoken = slib.currtoken()
            if ctoken == nil then
                line = line + 1
                token = 0
            end
        ---@diagnostic disable-next-line
        until ctoken ~= nil and ctoken.value == s
        if r then
            ret.onln = line
            ret.ontk = token
        end
    end

    function slib.setmark()
        slib.marks[slib.currtoken(-1).value] = {line=line, token=token}
    end

    function slib.gomark(name, ontk)
        local m = slib.marks[name]
        if m then
            ignore[slib.currtoken(-2)] = true
            ignore[slib.currtoken(-1)] = true

            ret.linetor = line
            ret.tokentor = token-1
            line = m.line
            token = m.token
            slib.line = line
        end
    end

    while true do
        line = line+1
        slib.line=line
        local content = lines[line]
        if content == nil then break end
        for i = 1, #content do
            token = i
            local this = content[token]
            ctoken = this

            if line == ret.onln and token == ret.ontk and ret.linetor ~= nil and ret.tokentor ~= nil then
                line = ret.linetor
                token = ret.tokentor

                ret = {}

                if slib.currtoken() == nil then
                    break
                end
            elseif ignore[this] == nil and this.type == 'keyword' then
                local cmd = keyword[this.value]
                local arguments = args(cmd.argc)
                table.insert(arguments, slib)

                local rcode = cmd.exec(table.unpack(arguments))
                if rcode == 1 then
                    break
                end
            end
        end
    end
end