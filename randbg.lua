#!/usr/bin/env lua

-- TODO: check that the file given by getFile has an image type extension

local File = ""
local Dir = ""
local Wildcard = ".*"

function printErrorQuit(msg)
	print(msg)
	os.exit(1)
end

-- an integer representing the seed to be used in the random number generation
-- change this function if you want
RandomSeedValue = os.time()

-- random int from a to b, both ends inclusive
local function randomIntRange(a, b)
	math.randomseed(math.floor(RandomSeedValue))

	-- Swap values if b < a
	if b < a then
		a, b = b, a
	end

	-- Calculate the range
	local range = b - a + 1

	return math.random(range) + a - 1
end

local function printHelp()
	print(
		arg[0] .. "\n\n"..
		"CLI Arguments:\n" ..
		"\t-help              - print this screen\n" ..
		"\t-file path_to_file - use a given file instead of randomly picking from a directory\n" ..
		"\t-dir path_to_dir   - use a given directory instead of the value of BG_DIR\n" ..
		"\t-seed number       - provide a custom seed for the random number generation, must be a number\n" ..
		"\twhatever_argument  - use the argument as a wildcard, the wildcard will be *whatever_argument* and the last such argument will be used as the wildcard\n" ..
		"Environment Variables:\n" ..
		"\tBG_DIR            - path to the folder containing your background images\n" ..
		"\tRANDBG_SILENT_FEH - 1 or true, makes the `feh` command completely silent including errors\n"
	)
end

local function parseArguments()
	local skipNext = false

	for i = 1, #arg do
		if skipNext then
			goto continue
		end

		if arg[i] == "-help" then
			printHelp()
			os.exit(0)
		elseif arg[i] == "-file" then
			File = arg[i + 1]
			skipNext = true
		elseif arg[i] == "-dir" then
			Dir = arg[i + 1]
			skipNext = true
		elseif arg[i] == "-seed" then
			local seed = tonumber(arg[i + 1])
			skipNext = true

			if seed == nil then
				printErrorQuit("RNG seed is not a number")
			end

			RandomSeedValue = seed
		else
			Wildcard = ".*" .. arg[i] .. ".*"
		end

		skipNext = false
		::continue::
	end
end

local function getFile(directoryPath, wildcard)
	local lfs = require "lfs"

	local function isFile(path)
		local attributes = lfs.attributes(path)
		return attributes and attributes.mode == "file"
	end

	local files = {}
	for file in lfs.dir(directoryPath) do
		if file == "." or file == ".." then
			goto continue
		end
		local filepath = directoryPath .. "/" .. file

		if filepath:match(wildcard) then
			if isFile(filepath) then
				table.insert(files, filepath)
			end
		end

		::continue::
	end

	return files[randomIntRange(1, #files)]
end

local function main()
	parseArguments()

	if Dir == "" then
		local bg_dir = os.getenv("BG_DIR")
		if bg_dir == nil then
			printErrorQuit("No folder available, use -dir path_to_folder or set BG_DIR")
		else
			Dir = bg_dir
		end
	end

	if File == "" then
		File = getFile(Dir, Wildcard)
	end

	assert(File ~= "", "ERROR: File is undefined")

	local cmd = ("feh --no-fehbg --bg-max %s"):format(File)
	local silentFeh = os.getenv("RANDBG_SILENT_FEH")
	if silentFeh == "1" or silentFeh == "true" then
		cmd = cmd .. " &> /dev/null"
	end

	local result = os.execute(cmd)
	if not result then
		print("ERROR: There was some error with feh, idk, open an issue on Github or something...")
	end
end

main()
