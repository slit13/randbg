#!/usr/bin/env lua

-- TODO: check that the file given by getFile has an image type extension

local File = ""
local Dir = ""
local Wildcard = ".*"
local RecursiveSearch = true

function printErrorQuit(msg)
	print(msg)
	os.exit(1)
end

-- an integer representing the seed to be used in the random number generation
-- default is os.time() but can be changed by setting RANDOM_SEED_EXPR
RandomSeedValue = os.time()
if os.getenv("RANDBG_SEED_EXPR") ~= nil then
	local expr, errorMessage = load("return " .. os.getenv("RANDBG_SEED_EXPR"))
	if expr ~= nil then
		if type(expr()) == "number" then
			RandomSeedValue = expr()
		end
	else
		print(errorMessage)
	end
end

-- random int from a to b, both ends inclusive
local function randomIntRange(a, b)
	-- ensure that RandomSeedValue is an integer
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
		"\t-no-recursive      - don't use recursive search, by default the script will search every subdirectory\n" ..
		"\twhatever_argument  - use the argument as a wildcard, the last such argument will be used as the wildcard\n" ..
		"Environment Variables:\n" ..
		"\tBG_DIR            - path to the folder containing your background images\n" ..
		"\tRANDBG_SILENT_FEH - 1 or true, makes the `feh` command completely silent including errors\n" ..
		"\tRANDBG_SEED_EXPR  - a Lua expression representing the random number generation seed, must be a number\n"
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
		elseif arg[i] == "-no-recursive" then
			RecursiveSearch = false
		else
			Wildcard = ".*" .. (arg[i]):gsub("%*", ".*") .. ".*"
		end

		skipNext = false
		::continue::
	end
end

local lfs = require "lfs"

local function isFile(path)
	local attributes = lfs.attributes(path)
	return attributes and attributes.mode == "file"
end

local function getFileRecursive(directoryPath, wildcard)
	local function isFile(path)
		local attributes = lfs.attributes(path)
		return attributes and attributes.mode == "file"
	end

	local function searchFiles(directoryPath, wildcard, files)
		for file in lfs.dir(directoryPath) do
			if file ~= "." and file ~= ".." then
				local filepath = directoryPath .. "/" .. file

				if isFile(filepath) and filepath:match(wildcard) then
					table.insert(files, filepath)
				elseif lfs.attributes(filepath, "mode") == "directory" then
					searchFiles(filepath, wildcard, files)
				end
			end
		end
	end

	local files = {}
	searchFiles(directoryPath, wildcard, files)

	return files[randomIntRange(1, #files)]
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
		if RecursiveSearch then
			File = getFileRecursive(Dir, Wildcard)
		else
			File = getFile(Dir, Wildcard)
		end
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
