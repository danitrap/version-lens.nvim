local M = {}

M.npm_parse_strategy = function(parsed)
	if not parsed.dependencies then
		return nil
	end

	local versions = {}
	for pkg, data in pairs(parsed.dependencies) do
		versions[pkg] = data.version
	end

	return versions
end

M.pnpm_parse_strategy = function(parsed)
	if #parsed == 0 then
		return nil
	end

	local versions = {}

	for _, entry in ipairs(parsed) do
		local npm_parser_strategy = M.npm_parse_strategy(entry)

		if npm_parser_strategy then
			for pkg, version in pairs(npm_parser_strategy) do
				versions[pkg] = version
			end
		end
	end

	return versions
end

return M
