local M = {}

---@class ChChChanges.Hunk
---@field filename string The file path
---@field lnum integer The line number where the hunk starts
---@field col integer The column number (default 1)
---@field text string The hunk description
---@field type string The type of change ('A' for added, 'D' for deleted, 'M' for modified)

---Get configuration value from vim.g with fallback
---@param key string The config key
---@param default any The default value
---@return any value The configuration value
local function get_config(key, default)
	local full_key = "chchchanges_" .. key
	return vim.g[full_key] ~= nil and vim.g[full_key] or default
end

---Parse git diff output and extract hunks
---@param diff_output string The output from git diff
---@return ChChChanges.Hunk[] hunks List of parsed hunks
local function parse_diff(diff_output)
	---@type ChChChanges.Hunk[]
	local hunks = {}

	local current_file = nil
	local lines = vim.split(diff_output, "\n", { plain = true })

	for _, line in ipairs(lines) do
		-- Parse file headers (diff --git a/file b/file or i/file w/file, etc)
		-- Git can use different prefixes (a/b, i/w, etc) depending on config
		local file_match = line:match("^diff %-%-git %w/(.-) %w/")
		if file_match then
			current_file = file_match
		end

		-- Parse hunk headers (@@ -start,count +start,count @@)
		local old_start, new_start = line:match("^@@ %-(%d+),?%d* %+(%d+),?%d* @@")
		if new_start and current_file then
			new_start = tonumber(new_start)

			-- Extract the context after @@ which often contains function/class names
			local context = line:match("^@@ .* @@ (.*)$") or ""

			-- Determine change type based on the diff content
			local change_type = "M" -- Modified by default

			table.insert(hunks, {
				filename = current_file,
				lnum = new_start or 1,
				col = 1,
				text = context ~= "" and ("Hunk: " .. context) or "Git hunk",
				type = change_type,
			})
		end
	end

	return hunks
end

---Get git diff for the current repository
---@return string|nil diff_output The git diff output or nil on error
---@return string|nil error_msg Error message if command failed
local function get_git_diff()
	-- Find git root directory
	local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	if vim.v.shell_error ~= 0 then
		return nil, "Not a git repository"
	end

	-- Build git diff command
	local git_cmd = get_config("git_cmd", "git")
	local diff_args = get_config("diff_args", {})

	local cmd = { git_cmd, "diff", "-U0", "--no-ext-diff" }
	if type(diff_args) == "table" then
		vim.list_extend(cmd, diff_args)
	end

	-- Execute git diff
	local output = vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then
		return nil, "Git diff failed: " .. output
	end

	return output, nil
end

---Debug function to show git diff output
---@return boolean success Whether the operation succeeded
function M.debug_diff()
	local diff_output, err = get_git_diff()
	if not diff_output then
		vim.notify("chchchanges: " .. (err or "Unknown error"), vim.log.levels.ERROR)
		return false
	end

	-- Write diff output to a temp file for inspection
	local tmpfile = vim.fn.tempname() .. "_git_diff.txt"
	vim.fn.writefile(vim.split(diff_output, "\n"), tmpfile)
	vim.cmd("vsplit " .. tmpfile)

	vim.notify(string.format("Git diff output written to: %s (%d bytes)", tmpfile, #diff_output), vim.log.levels.INFO)
	return true
end

---Populate quickfix list with git hunks
---@param opts table|nil Optional configuration
---@return boolean success Whether the operation succeeded
function M.populate_quickfix(opts)
	opts = opts or {}

	-- Get git diff
	local diff_output, err = get_git_diff()
	if not diff_output then
		vim.notify("chchchanges: " .. (err or "Unknown error"), vim.log.levels.ERROR)
		return false
	end

	-- Check if there are any changes
	if diff_output == "" then
		vim.notify("chchchanges: No changes detected", vim.log.levels.INFO)
		return true
	end

	-- Parse diff and extract hunks
	local hunks = parse_diff(diff_output)

	if #hunks == 0 then
		vim.notify("chchchanges: No hunks found", vim.log.levels.WARN)
		return true
	end

	-- Convert hunks to quickfix format
	---@type table[]
	local qf_items = {}
	for _, hunk in ipairs(hunks) do
		table.insert(qf_items, {
			filename = hunk.filename,
			lnum = hunk.lnum,
			col = hunk.col,
			text = hunk.text,
			type = hunk.type,
		})
	end

	-- Set quickfix list
	vim.fn.setqflist(qf_items, opts.action or "r")

	-- Set quickfix title
	vim.fn.setqflist({}, "a", { title = "Git Changes (Hunks)" })

	-- Open quickfix window if requested
	if opts.open ~= false then
		vim.cmd("copen")
	end

	vim.notify(
		string.format("chchchanges: Added %d hunk%s to quickfix", #hunks, #hunks == 1 and "" or "s"),
		vim.log.levels.INFO
	)

	return true
end

return M
