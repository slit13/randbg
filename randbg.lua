#!/usr/bin/env lua

-- TODO: check that the file given by getFile has an image type extension

local File = ""
local Dir = ""
local Wildcard = ".*"

-- random int from a to b, both ends inclusive
local function randomIntRange(a, b)
	-- returns an integer representing the seed to be used in the random number generation
	-- change this function if you want
	local function randomSeedValue()
		math.randomseed(os.time(), math.floor(os.time() / 2))
	end

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
		arg[0] .. "\n"..
		"\t-help              - print this screen\n" ..
		"\t-file path_to_file - use a given file instead of randomly picking from a directory\n" ..
		"\t-dir path_to_dir   - use a given directory instead of the value of BG_DIR\n" ..
		"\twhatever_argument  - use the argument as a wildcard, the wildcard will be *whatever_argument* and the last such argument will be used as the wildcard"
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
			print("No folder available, use -dir path_to_folder or set BG_DIR")
			os.exit(1)
		else
			Dir = bg_dir
		end
	end

	if File == "" then
		File = getFile(Dir, Wildcard)
	end

	assert(File ~= "", "ERROR: File is undefined")

	local cmd = ("feh --no-fehbg --bg-max %s"):format(File)
	os.execute(cmd)
end

main()
