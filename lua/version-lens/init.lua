-- Plugin to display installed versions in virtual text when opening package.json

local strategies = require("version-lens.strategies")

local M = {}

---@class version-lens.PackageManager
---@field lockfile string
---@field list_cmd string
---@field parse_strategy fun(output: string): table<string, string>

---@type table<string, version-lens.PackageManager>
PACKAGE_MANAGERS = {
	npm = {
		lockfile = "package-lock.json",
		list_cmd = "npm list --depth=0 --json",
		parse_strategy = strategies.npm_parse_strategy,
	},
	pnpm = {
		lockfile = "pnpm-lock.yaml",
		list_cmd = "pnpm list --depth=0 --json",
		parse_strategy = strategies.pnpm_parse_strategy,
	},
	yarn = {
		lockfile = "yarn.lock",
		list_cmd = "yarn list --depth=0",
		parse_strategy = strategies.yarn_parse_strategy,
	},
}

---@return boolean is_package_json Is the current file a package.json file
local function is_package_json()
	return vim.fn.expand("%:t") == "package.json"
end

---@return string? manager The package manager used in the current project
local function get_package_manager()
	for manager, entry in pairs(PACKAGE_MANAGERS) do
		if vim.fn.filereadable(entry.lockfile) == 1 then
			return manager
		end
	end

	return nil
end

---@return table<string, string>? versions A table containing package names and their versions
local function fetch_versions()
	local manager = get_package_manager()
	if not manager then
		return nil
	end

	local pkg_manager_spec = PACKAGE_MANAGERS[manager]

	local cmd = vim.split(pkg_manager_spec.list_cmd, " ")

	local result = vim.system(cmd):wait()
	if result.code ~= 0 or not result.stdout then
		return nil
	end

	return pkg_manager_spec.parse_strategy(result.stdout)
end

---@return nil
local function add_virtual_text()
	if not is_package_json() then
		return
	end

	local versions = fetch_versions()
	if not versions then
		return
	end

	local ns_id = vim.api.nvim_create_namespace("PackageLockVirtualText")
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	for i, line in ipairs(lines) do
		local pkg_name = line:match('"([^"]+)":')
		if pkg_name and versions[pkg_name] then
			vim.api.nvim_buf_set_extmark(0, ns_id, i - 1, -1, {
				virt_text = { { " " .. versions[pkg_name], "Comment" } },
				virt_text_pos = "eol",
			})
		end
	end
end

---@return nil
function M.setup()
	local group = vim.api.nvim_create_augroup("VersionLens", { clear = true })

	vim.api.nvim_create_autocmd("BufReadPost", {
		group = group,
		pattern = "package.json",
		callback = add_virtual_text,
		desc = "Add virtual text showing installed package versions",
	})
end

return M
