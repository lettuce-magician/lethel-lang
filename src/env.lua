local f = string.format
local logging = require "logging"
local stack = {}

local keyword = {}
local solokeyword = {}
local labels = {}
local values = {}

local function newkeyword(name, argc, func)
    keyword[name] = {
        args = argc or 0,
        exec = func,
    }
end

local function checktype(this, type, keywrd)
    keywrd = keywrd or this.value
    if this.type ~= type then
        logging.run(
            f(
                "%s wants %s, but you gave him %s. You meanie >:(", keywrd, type, this.type
            ),
            4
        )
    end
end

local function getvalues(...)
    local t = {}
    for _, v in ipairs({...}) do
        if stack[v] ~= nil then
            table.insert(t, stack[v])
        end
    end
    return table.unpack(t)
end

local function toboolean(value)
    if value == "true" then
        return true
    elseif value == "false" or value==nil then
        return false
    elseif value ~= nil then
        return true
    end
end

local function isnumber(value)
    if value == nil then
        return false
    elseif tonumber(value) ~= nil then
        return true
    end
end

local function checkactualtype(this, type, keywrd)
    keywrd = keywrd or this.value
    local is = (type == 'number' and tonumber(this.value) ~= nil)
    or (type == 'string' and this.value:gsub('%a', '') == "")
    or (type == 'boolean' and toboolean(this.value))

    if is == false then
        logging.run(
            f(
                "%s wants %s, but you gave him %s. You meanie >:(", keywrd, type, this.type
            ),
            4
        )
    end
end

----------------------- keywords
newkeyword('push', 1, function (val)
    checktype(val, 'ident', 'push')
    stack[#stack + 1] = val.value
end)
newkeyword('last', 0, function ()
    stack[#stack+1] = stack[#stack]
end)
newkeyword('pop', 0, function ()
    stack[#stack] = nil
end)
newkeyword('first', 0, function ()
    stack[#stack+1] = stack[1]
end)
newkeyword('oper', 1, function (operation)
    checktype(operation, 'operator', 'oper')
    local a, b = getvalues(1, 2)
    local result

    if type(a) ~= "number" then
        a = tonumber(a)
    elseif type(b) ~= "number" then
        b = tonumber(b)
    end

    if operation.value == '+' then
        result = a + b
    elseif operation.value == '-' then
        result = a - b
    elseif operation.value == '*' then
        result = a * b
    elseif operation.value == '/' then
        result = a / b
    end

    stack[#stack + 1] = result
end)
newkeyword('bit', 1, function (bitwise)
    checktype(bitwise, 'bitwise', 'bit')
    local a, b = getvalues(1, 2)
    local val

    if bitwise.value == '=' then
        val = (a==b)
    elseif bitwise.value == '&' then
        val = (a and b)
    elseif bitwise.value == '|' then
        val = (a or b)
    elseif bitwise.value == '~' then
        val = (a ~= b)
    end

    stack[#stack + 1] = tostring(val)
end)
newkeyword('print', 0, function ()
    print(stack[#stack])
end)
newkeyword('clear', 0, function()
    stack = {}
end)
newkeyword('jump', 1, function (line, slib)
    checktype(line, 'ident', 'jump')
    checkactualtype(line, 'number', 'jump')
    slib.cline(line.value)
end)
newkeyword('cjump', 2, function (line, elseline, slib)
    checktype(line, 'ident', 'cjump')
    checktype(elseline, 'ident', 'cjump')
    checkactualtype(line, 'number', 'cjump')
    checkactualtype(elseline, 'number', 'cjump')

    if toboolean(stack[#stack]) == true then
        slib.cline(line.value)
    elseif toboolean(stack[#stack]) == false then
        slib.cline(elseline.value)
    end
end)
newkeyword('label', 1, function (name, slib)
    checktype(name, 'ident', 'label')
    labels[name.value] = true
    slib.setmark()
    slib.ignore('done', true)
end)
newkeyword('call', 1, function (name, slib)
    checktype(name, 'ident', 'call')
    if labels[name.value] then
        slib.gomark(name.value, 'done')
    else
        logging.run("the uhhh mmm label "..name.value.." uhhh dosent exists idk", 4)
    end
end)
newkeyword('done', 0, function ()
end)
newkeyword('len', 0, function ()
    stack[#stack+1] = #stack
end)
newkeyword('value', 2, function (name, val)
    checktype(name, 'ident', 'value')
    checktype(val, 'ident', 'value')

    values[name.value] = val.value
end)
newkeyword('pushval', 1, function (name)
    checktype(name, 'ident', 'pushval')
    if values[name.value] then
        stack[#stack+1] = values[name.value]
    else
        logging.run("the uhhh mmm value "..name.value.." uhhh dosent exists idk", 4)
    end
end)
newkeyword('concat', 1, function (st)
    checktype(st, 'ident', 'concat')
    checkactualtype(st, 'number', 'concat')
    local s = ''
    if tonumber(st.value) > 0 then

        for i = 1, tonumber(st.value) do
            if stack[i] ~= nil then
                s = s..stack[i]
                stack[i] = nil
            end
        end
    elseif tonumber(st.value) < 0 then
        for i = -tonumber(st.value), 1, -1 do
            if stack[i] ~= nil then
                s = s..stack[i]
                stack[i] = nil
            end
        end
    else
        logging.run("if you dont wanna concat any shit then dont use concat moron", 4)
    end
    stack[1] = s
end)
newkeyword('pos', 1, function (num)
    checktype(num, 'ident', 'pos')
    checkactualtype(num, 'number', 'pos')

    stack[#stack+1] = stack[tonumber(num.value)]
end)
newkeyword('rem', 1, function (num)
    checktype(num, 'ident', 'rem')
    checkactualtype(num, 'number', 'rem')
    table.remove(stack, tonumber(num.value))
end)
----------------------- meme keywords
newkeyword('class', 0, function ()
    logging.run('oop sucks lol', 4)
end)
newkeyword('#define', 0, function ()
    while true do
        print('GETOUTOFMYHEAD')
    end
end)
----------------------- values
values["_"] = " "
----------------------- solokeywords

for k in pairs(keyword) do
    table.insert(solokeyword, k)
end

return {
    keyword = keyword,
    solokeyword = solokeyword,
}