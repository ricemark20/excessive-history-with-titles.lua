local msg = require "mp.msg"
local utils = require "mp.utils"

local HISTFILE = (mp.find_config_file("mpv.conf"):sub(0,-9)).."history-with-titles.txt"
local loggerfile
local started
local paused
local firstseek
local seeking
local a_time
local b_time
local time_pos
local a_pos
local b_pos

function get_a_time_and_pos()
    a_time = mp.get_time()
    a_pos = mp.get_property("time-pos")
end

function logtime()
    loggerfile:write(("<%s>\n"):format(os.date("%d/%b/%Y %X")))
end

function logplay(title)
    get_a_time_and_pos()
    logtime()
    loggerfile:write(("play %s %s\n"):format(a_pos, title))
end

mp.register_event("file-loaded", function()
    started = false
    local title = mp.get_property("media-title") or ""
    loggerfile:write(("%s\n"):format(mp.get_property("path")))
    if not mp.get_property_bool("pause") then
        started = true
        logplay(title)
    end
    firstseek = mp.get_property_bool("seeking") and true or false
end)

mp.observe_property("pause", "bool", function(name, value)
    time_pos = mp.get_property("time-pos")
    if value == true and started then
        paused = true
        loggerfile:write(("pause %s\n"):format(time_pos))
    end
    if started == false then
        started = true
    end
    if value == false and started then
        paused = false
        local title = mp.get_property("media-title") or ""
        logplay(title)
    end
end)

mp.observe_property("seeking", "bool", function(name, value)
    time_pos = mp.get_property("time-pos")
    if value == false then
        seeking = false
        if firstseek then
            firstseek = false
        else
            if not mp.get_property_bool("pause") then
                if time_pos ~= nil then
                    logtime()
                    loggerfile:write(("seek stop %s "):format(time_pos))
                end
            end
            get_a_time_and_pos()
        end
    end
end)

mp.register_event("seek", function()
    if (not firstseek) and (not seeking) and (not mp.get_property_bool("pause")) then
        b_time = mp.get_time()
        b_pos = a_pos + (b_time - a_time)
        loggerfile:write(("seek start %s\n"):format(b_pos))
        seeking = true
    end
end)

mp.register_event("end-file", function()
    if (started and (not paused)) then
        b_time = mp.get_time()
        b_pos = a_pos + (b_time - a_time)
        loggerfile:write(("end %s\n"):format(b_pos))
    end
    loggerfile:write("\n")
end)

mp.register_event("shutdown", function()
    loggerfile:close()
end)

loggerfile = io.open(HISTFILE, "a+")

