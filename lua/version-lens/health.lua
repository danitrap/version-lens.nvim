local M = {}

M.check = function()
	vim.health.start("version-lens report")

	if vim.fn.executable("npm") == 0 then
		vim.health.warn("npm is not installed")
	else
		vim.health.ok("npm found on path")
	end

	if vim.fn.executable("pnpm") == 0 then
		vim.health.warn("pnpm is not installed")
	else
		vim.health.ok("pnpm found on path")
	end

	if vim.fn.executable("yarn") == 0 then
		vim.health.warn("yarn is not installed")
	else
		vim.health.ok("yarn found on path")
	end
end

return M
