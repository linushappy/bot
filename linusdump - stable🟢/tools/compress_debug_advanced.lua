-- Advanced compressor: collapses repeated single-line and multi-line sequences
-- Usage: lua compress_debug_advanced.lua [input_file]
-- If no input_file is provided, reads from stdin

local input_path = arg and arg[1]
local fh
if input_path then
    local err
    fh, err = io.open(input_path, "r")
    if not fh then
        io.stderr:write("Error opening file: " .. tostring(err) .. "\n")
        os.exit(1)
    end
end

local lines = {}
local read = fh and function() return fh:read("*l") end or function() return io.read("*l") end
while true do
    local l = read()
    if not l then break end
    table.insert(lines, l)
end
if fh then fh:close() end

local n = #lines
local i = 1
local maxPatternLen = 8

local function repeat_count_at(pos, plen)
    if pos + plen - 1 > n then return 0 end
    local count = 1
    while true do
        local base = pos + count * plen
        if base + plen - 1 > n then break end
        local ok = true
        for j = 1, plen do
            if lines[pos + j - 1] ~= lines[base + j - 1] then
                ok = false
                break
            end
        end
        if not ok then break end
        count = count + 1
    end
    return count
end

while i <= n do
    local used = false
    for plen = math.min(maxPatternLen, n - i + 1), 1, -1 do
        local cnt = repeat_count_at(i, plen)
        if cnt > 1 then
            local pattern = {}
            for j = 1, plen do table.insert(pattern, lines[i + j - 1]) end
            local joined = table.concat(pattern, " | ")
            if plen == 1 then
                print(string.format("%s  (repeated %d times)", joined, cnt))
            else
                print(string.format("(%s)  (repeated %d times)", joined, cnt))
            end
            i = i + cnt * plen
            used = true
            break
        end
    end
    if not used then
        print(lines[i])
        i = i + 1
    end
end
