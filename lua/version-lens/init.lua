-- Plugin to display installed versions in virtual text when opening package.json

local M = {}

---@class PackageManager
---@field lockfile string
---@field list_cmd string

---@type table<string, PackageManager>
PACKAGE_MANAGERS = {
	npm = {
		lockfile = "package-lock.json",
		list_cmd = "npm list --depth=0 --json",
	},
	pnpm = {
		lockfile = "pnpm-lock.yaml",
		list_cmd = "pnpm list --depth=0 --json",
	},
	yarn = {
		lockfile = "yarn.lock",
		list_cmd = "yarn list --depth=0 --json",
	},
}

local function is_package_json()
	return vim.fn.expand("%:t") == "package.json"
end

local function get_package_manager()
	for manager, entry in pairs(PACKAGE_MANAGERS) do
		if vim.fn.filereadable(entry.lockfile) == 1 then
			return manager
		end
	end

	return nil
end

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

	local ok, parsed = pcall(vim.fn.json_decode, result.stdout)
	if not ok or not parsed.dependencies then
		return nil
	end

	local versions = {}
	for pkg, data in pairs(parsed.dependencies) do
		versions[pkg] = data.version
	end

	return versions
end

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
