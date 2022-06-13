local log = {}

log.colors = {
    "\27[32m",
    "",
    "\27[33m",
    "\27[31m",
}

log.special = {
    reset = "\27[0m",
    bold = "\27[1m",
    dim = "\27[2m",
    underline = "\27[4m",
    blink = "\27[5m",
    reverse = "\27[7m",
    hidden = "\27[8m",
}

log.level = {
    debug = 1,
    info = 2,
    warn = 3,
    error = 4,
}

log.texts = {
    "debug",
    "",
    "warn",
    "error",
    "fatal"
}

log.out = {
    debug = io.stdout,
    info = io.stdout,
    warn = io.stderr,
    error = io.stderr,
}

function log.run(msg, level)
    local color = log.colors[level] or 2
    local prefix = log.texts[level]
    local out = log.out[prefix]

    out:write(color..prefix..": "..msg.."\n"..log.special.reset)
    out:flush()

    if level == 4 then
        os.exit(1)
    end
end

function log.assert(condit, msg)
    if condit == false then
        log.run(msg or 'assertion failed!', 4)
    end
end

return log