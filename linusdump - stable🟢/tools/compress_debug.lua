-- Compress consecutive identical lines in a debug log
-- Usage: lua compress_debug.lua [input_file]
-- If no input_file is provided, reads from stdin

local input_path = arg and arg[1]
local getLine
if input_path then
    local fh, err = io.open(input_path, "r")
    if not fh then
        io.stderr:write("Error opening file: " .. tostring(err) .. "\n")
        os.exit(1)
    end
    getLine = function() return fh:read("*l") end
else
    getLine = function() return io.read("*l") end
end

local prev
local count = 0
local function flush()
    if not prev then return end
    if count == 1 then
        print(prev)
    else
        print(string.format("%s  (repeated %d times)", prev, count))
    end
end

while true do
    local line = getLine()
    if not line then break end
    if line == prev then
        count = count + 1
    else
        flush()
        prev = line
        count = 1
    end
end
flush()
