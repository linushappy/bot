local luau = require("@lune/luau")
local Sandbox = require("./sandbox/build")

local Runner = {}

local function detectObfuscation(source: string): string
	local lowercaseSource = string.lower(source)
	
	-- Check for Luraph (obfuscator with specific patterns)
	if string.find(source, "_25mspredefined") or string.find(lowercaseSource, "zeenjunkie") or string.find(source, "luraphcarry") then
		return "luraph"
	end
	
	-- Check for LuaObf strings obfuscation
	if string.find(source, "luaobf_decrypt_strings") then
		return "luaobf_strings"
	end
	
	-- Check for Moonsec
	if string.find(lowercaseSource, "moonsec") or string.find(source, "ClosureEnvironment") then
		return "moonsec"
	end
	
	-- Check for Moonveil
	if string.find(lowercaseSource, "moonveil") or string.find(source, "moonveil") then
		return "moonveil"
	end
	
	-- Check for IronBrew
	if string.find(lowercaseSource, "ironbrew") or string.find(source, "IronBrew") then
		return "ironbrew"
	end
	
	-- Check for WeAreDevs
	if string.find(lowercaseSource, "wearedevs") or string.find(lowercaseSource, "wearedevs.net") then
		return "wearedevs"
	end
	
	-- Check for LPS (Lua Placeholder System)
	if string.find(source, "LPS") or string.find(source, "%[%[LPS") then
		return "lps"
	end
	
	-- Check for Prometheus
	if string.find(lowercaseSource, "prometheus") or string.find(source, "_prometheus") then
		return "prometheus"
	end
	
	-- Check for general obfuscation patterns (if/else/then/return heavy)
	local function countOccurrences(text, substring)
		if substring == "" then
			return 0
		end
		return select(2, string.gsub(text, substring, ""))
	end

	local ifCount = countOccurrences(source, "if")
	local elseCount = countOccurrences(source, "else")
	local thenCount = countOccurrences(source, "then")
	local returnCount = countOccurrences(source, "return")
	local localCount = countOccurrences(source, "local")
	
	local obfuscationScore = ifCount + elseCount + thenCount + returnCount + localCount
	if obfuscationScore > 100 then
		return "general"
	end
	
	return "unknown"
end

local function buildBanner(statusEmoji: string, durationMs: number, obfuscationType: string)
	return {
		"--[[",
		"                                                              ",
		"▄▄▄      ▄▄▄                       ▄▄                         ",
		"████▄  ▄████             ▄▄        ██        ██          ██   ",
		"███▀████▀███  ▀▀█▄ ████▄ ██ ▄█▀ ▄████ ▄█▀█▄ ▀██▀▀ ▄█▀█▄ ▀██▀▀ ",
		"███  ▀▀  ███ ▄█▀██ ██ ▀▀ ████   ██ ██ ██▄█▀  ██   ██▄█▀  ██   ",
		"███      ███ ▀█▄██ ██    ██ ▀█▄ ▀████ ▀█▄▄▄  ██   ▀█▄▄▄  ██   ",
		"                                                              ",
		"▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ ",
		"████████████████ [timestamp: " .. tostring(durationMs) .. " ms]",
		"██▀▄▄▀████▀▄▄▀██ [Dumped by: linusdump]",
		"████████████████ [status: " .. statusEmoji .. "]",
		"██▀██████████▀██ [type: " .. obfuscationType .. "]",
		"██▄▄▄▄▄▄▄▄▄▄▄▄██",
		"▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀",
		"                                                              ",
		"--]]",
		"",
	}
end

local function buildOutput(state: any, bannerLines: {string}, traces: {string})
local out = {}

for _, line in ipairs(bannerLines) do
table.insert(out, line)
end

for _, line in ipairs(traces) do
table.insert(out, line)
end

if #traces > 0 then
table.insert(out, "")
end

for _, line in ipairs(state.output) do
table.insert(out, line)
end

return table.concat(out, "\n")
end

function Runner.execute(source: string): (boolean, string, string?)
local env, state, codegen = Sandbox.build()

local startTime = os.clock()
local traces = {}

local function trace(message: string)
	table.insert(traces, "-- TRACE: " .. message)
end

trace("source length=" .. tostring(#source) .. " bytes")

-- Detect obfuscation type
local obfuscationType = detectObfuscation(source)
trace("obfuscation detected: " .. obfuscationType)

local loadSuccess, fnOrErr = pcall(function()
	return luau.load(source, {environment = env})
end)

if not loadSuccess or type(fnOrErr) ~= "function" then
	trace("load failed: " .. tostring(fnOrErr))
	local banner = buildBanner("RED", math.floor((os.clock() - startTime) * 1000 + 0.5), obfuscationType)
	return false, buildOutput(state, banner, traces), tostring(fnOrErr)
end

trace("load succeeded")

local fn = fnOrErr
if type(fn) ~= "function" then
	trace("load did not return a function")
	local banner = buildBanner("RED", math.floor((os.clock() - startTime) * 1000 + 0.5), obfuscationType)
	return false, buildOutput(state, banner, traces), "load did not return a function"
end
	
	local execSuccess, execErr
do
local stepCount = 0
local MAX_HOOK_CALLS = 5000
local MAX_EXEC_SECONDS = 5

local function removeHook()
if type(debug) == "table" and type(debug.sethook) == "function" then
debug.sethook()
end
end

local function hook()
stepCount += 1
if stepCount >= MAX_HOOK_CALLS or (stepCount % 100 == 0 and os.clock() - startTime >= MAX_EXEC_SECONDS) then
error("[mimic] execution timeout")
end
end

local debugAvailable = type(debug) == "table" and type(debug.sethook) == "function"
if not debugAvailable then
trace("debug hook unavailable")
end

if debugAvailable then
debug.sethook(hook, "", 1000)
local ok, err = xpcall(fn, function(e)
removeHook()
return e
end)
removeHook()
execSuccess, execErr = ok, err
else
execSuccess, execErr = pcall(fn)
end
end

if execSuccess then
trace("execution succeeded")
else
trace("execution halted: " .. tostring(execErr))
codegen:emitLine("")
codegen:emitLine(codegen:comment("Execution halted: " .. tostring(execErr)))
end

local durationMs = math.floor((os.clock() - startTime) * 1000 + 0.5)
local banner = buildBanner(execSuccess and "🟢" or "🔴", durationMs, obfuscationType)

return execSuccess, buildOutput(state, banner, traces), execSuccess and nil or tostring(execErr)
end

return Runner