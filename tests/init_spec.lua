describe("version-lens", function()
	local version_lens = require("version-lens")

	-- Mock vim namespace
	local mock_extmarks = {}
	local mock_namespace_id = 1
	local mock_buf_lines = {}
	local mock_autocmds = {}

	before_each(function()
		-- Reset mocks
		mock_extmarks = {}
		mock_buf_lines = {}
		mock_autocmds = {}

		-- Mock vim.api functions
		vim.api.nvim_create_namespace = function()
			return mock_namespace_id
		end

		vim.api.nvim_buf_set_extmark = function(bufnr, ns_id, line, col, opts)
			table.insert(mock_extmarks, {
				bufnr = bufnr,
				ns_id = ns_id,
				line = line,
				col = col,
				opts = opts,
			})
		end

		vim.api.nvim_buf_get_lines = function()
			return mock_buf_lines
		end

		vim.api.nvim_create_autocmd = function(event, opts)
			table.insert(mock_autocmds, { event = event, opts = opts })
		end

		-- Mock vim.fn functions
		vim.fn.expand = function(expr)
			if expr == "%:t" then
				return "package.json"
			end
			return ""
		end

		vim.fn.filereadable = function(file)
			if file == "package-lock.json" then
				return 1
			end
			return 0
		end

		vim.fn.json_decode = function(json)
			return vim.json.decode(json)
		end

		-- Mock vim.system
		vim.system = function(cmd)
			return {
				wait = function()
					if cmd[1] == "npm" then
						return {
							code = 0,
							stdout = [[
                        {
                            "dependencies": {
                                "lodash": {
                                    "version": "4.17.21"
                                },
                                "express": {
                                    "version": "4.18.2"
                                }
                            }
                        }
                    ]],
						}
					elseif cmd[1] == "pnpm" then
						return {
							code = 0,
							stdout = [[
              [
                        {
                            "dependencies": {
                                "lodash": {
                                    "version": "4.17.21"
                                },
                                "express": {
                                    "version": "4.18.2"
                                }
                            }
                        }
              ]
              ]],
						}
					elseif cmd[1] == "yarn" then
						return {
							code = 0,
							stdout = [[
              ├─ lodash@4.17.21
              ├─ express@4.18.2
              ├─ @fake/dependency@4.1.1
              └─ tslib@2.8.1
              ]],
						}
					end
					return { code = 1, stdout = "" }
				end,
			}
		end
	end)

	describe("setup", function()
		it("should create autocmd for package.json files", function()
			version_lens.setup()

			assert.equals(1, #mock_autocmds)
			assert.equals("BufReadPost", mock_autocmds[1].event)
			assert.equals("package.json", mock_autocmds[1].opts.pattern)
		end)
	end)

	describe("virtual text", function()
		it("should add version information as virtual text", function()
			mock_buf_lines = {
				"{",
				'  "dependencies": {',
				'    "lodash": "^4.0.0",',
				'    "express": "^4.0.0"',
				"  }",
				"}",
			}

			version_lens.setup()
			-- Simulate BufReadPost event
			local autocmd_callback = mock_autocmds[1].opts.callback
			autocmd_callback()

			-- Check if virtual text was added correctly
			assert.equals(2, #mock_extmarks)
			assert.equals(" 4.17.21", mock_extmarks[1].opts.virt_text[1][1])
			assert.equals(" 4.18.2", mock_extmarks[2].opts.virt_text[1][1])
		end)

		it("should work with pnpm package manager", function()
			mock_buf_lines = {
				"{",
				'  "dependencies": {',
				'    "lodash": "^4.0.0",',
				'    "express": "^4.0.0"',
				"  }",
				"}",
			}

			vim.fn.filereadable = function(file)
				if file == "pnpm-lock.yaml" then
					return 1
				end
				return 0
			end

			version_lens.setup()
			-- Simulate BufReadPost event
			local autocmd_callback = mock_autocmds[1].opts.callback
			autocmd_callback()

			-- Check if virtual text was added correctly
			assert.equals(2, #mock_extmarks)
			assert.equals(" 4.17.21", mock_extmarks[1].opts.virt_text[1][1])
			assert.equals(" 4.18.2", mock_extmarks[2].opts.virt_text[1][1])
		end)

		it("should work with yarn package manager", function()
			mock_buf_lines = {
				"{",
				'  "dependencies": {',
				'    "lodash": "^4.0.0",',
				'    "express": "^4.0.0"',
				'    "@fake/dependency": "^4.0.0"',
				"  },",
				'  "devDependencies": {',
				'    "tslib": "^2.8.0"',
				"  }",
				"}",
			}

			vim.fn.filereadable = function(file)
				if file == "yarn.lock" then
					return 1
				end
				return 0
			end

			version_lens.setup()
			-- Simulate BufReadPost event
			local autocmd_callback = mock_autocmds[1].opts.callback
			autocmd_callback()

			-- Check if virtual text was added correctly
			assert.equals(4, #mock_extmarks)
			assert.equals(" 4.17.21", mock_extmarks[1].opts.virt_text[1][1])
			assert.equals(" 4.18.2", mock_extmarks[2].opts.virt_text[1][1])
			assert.equals(" 4.1.1", mock_extmarks[3].opts.virt_text[1][1])
			assert.equals(" 2.8.1", mock_extmarks[4].opts.virt_text[1][1])
		end)
	end)
end)
