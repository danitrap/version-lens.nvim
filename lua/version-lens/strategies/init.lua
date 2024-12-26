local M = {}

M.npm_like_parser = function(parsed)
	if not parsed.dependencies then
		return nil
	end

	local versions = {}
	for pkg, data in pairs(parsed.dependencies) do
		versions[pkg] = data.version
	end

	return versions
end

---Parse the output of `npm list --depth=0 --json` and return a table with package names and their versions
---@param output string
---@return table<string, string>? versions
M.npm_parse_strategy = function(output)
	local ok, parsed = pcall(vim.fn.json_decode, output)
	if not ok then
		return nil
	end

	return M.npm_like_parser(parsed)
end

---Parse the output of `pnpm list --depth=0 --json` and return a table with package names and their versions
---@param output string
---@return table<string, string>? versions
M.pnpm_parse_strategy = function(output)
	local ok, parsed = pcall(vim.fn.json_decode, output)
	if not ok then
		return nil
	end

	if #parsed == 0 then
		return nil
	end

	local versions = {}

	for _, entry in ipairs(parsed) do
		local npm_parser_strategy = M.npm_like_parser(entry)

		if npm_parser_strategy then
			for pkg, version in pairs(npm_parser_strategy) do
				versions[pkg] = version
			end
		end
	end

	return versions
end

---Parse the output of `yarn list --depth=0` and return a table with package names and their versions
---@param output string
---@return table<string, string>? versions
M.yarn_parse_strategy = function(output)
	local versions = {}

	for line in output:gmatch("[^\r\n]+") do
		if not line:match("^yarn%s+list") and #line > 0 then
			-- Match both ├ (\226\148\156) and └ (\226\148\148) characters
			local pkg, version = line:match("%s*[\226\148\156\226\148\148]\226\148\128%s+([^@]+)@([%d%.]+)")

			if pkg and version then
				versions[pkg] = version
			end
		end
	end

	if next(versions) == nil then
		return nil
	end

	return versions
end

return M
