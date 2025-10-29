-- Simple test for parsing git diff output
-- Run with: nvim --headless -c "luafile tests/parse_spec.lua" -c "qa!"

local test_dir = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ':h')
local root_dir = vim.fn.fnamemodify(test_dir, ':h')
vim.opt.runtimepath:prepend(root_dir)

local chchchanges = require('chchchanges')

-- Test helper
local function assert_eq(actual, expected, message)
	if actual ~= expected then
		error(string.format('%s\nExpected: %s\nActual: %s', message or 'Assertion failed', vim.inspect(expected), vim.inspect(actual)))
	end
end

local function run_test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		print('✓ ' .. name)
	else
		print('✗ ' .. name)
		print('  ' .. tostring(err))
	end
	return ok
end

-- We need to expose parse_diff for testing
-- Let's add a test helper to the module
local function parse_diff_from_string(diff_output)
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

-- Test 1: Parse simple diff
run_test('Parse simple git diff', function()
	local fixture_path = test_dir .. '/fixtures/simple_diff.txt'
	local diff_content = table.concat(vim.fn.readfile(fixture_path), '\n')

	print('\n--- Diff content ---')
	print(diff_content)
	print('--- End diff content ---\n')

	local hunks = parse_diff_from_string(diff_content)

	print(string.format('\nFound %d hunks', #hunks))
	for i, hunk in ipairs(hunks) do
		print(string.format('Hunk %d: %s:%d - %s', i, hunk.filename, hunk.lnum, hunk.text))
	end

	assert_eq(#hunks, 2, 'Should find 2 hunks')
	assert_eq(hunks[1].filename, 'lua/chchchanges.lua', 'First hunk should be in lua/chchchanges.lua')
	assert_eq(hunks[1].lnum, 10, 'First hunk should start at line 10')
end)

-- Test 2: Parse diff with mnemonic prefixes (i/w instead of a/b)
run_test('Parse git diff with mnemonic prefixes', function()
	local fixture_path = test_dir .. '/fixtures/mnemonic_prefix_diff.txt'
	local diff_content = table.concat(vim.fn.readfile(fixture_path), '\n')

	print('\n--- Testing mnemonic prefix diff ---')
	local hunks = parse_diff_from_string(diff_content)

	print(string.format('Found %d hunks', #hunks))
	for i, hunk in ipairs(hunks) do
		print(string.format('Hunk %d: %s:%d - %s', i, hunk.filename, hunk.lnum, hunk.text))
	end

	assert_eq(#hunks, 3, 'Should find 3 hunks')
	assert_eq(hunks[1].filename, 'src/app.css', 'First hunk should be in src/app.css')
	assert_eq(hunks[1].lnum, 44, 'First hunk should start at line 44')
	assert_eq(hunks[2].filename, 'src/app.css', 'Second hunk should be in src/app.css')
	assert_eq(hunks[3].filename, 'src/lib/components/ui/button/button.svelte', 'Third hunk should be in button.svelte')
end)

-- Test 3: Test with empty diff
run_test('Parse empty diff', function()
	local hunks = parse_diff_from_string('')
	assert_eq(#hunks, 0, 'Should find 0 hunks in empty diff')
end)

-- Test 4: Test hunk header pattern matching
run_test('Match hunk header pattern', function()
	local test_lines = {
		'@@ -10,7 +10,7 @@ local M = {}',
		'@@ -88,6 +88,10 @@ end',
		'@@ -1 +1,2 @@',
		'@@ -5,3 +5 @@',
	}

	for _, line in ipairs(test_lines) do
		local old_start, new_start = line:match("^@@ %-(%d+),?%d* %+(%d+),?%d* @@")
		print(string.format('Line: %s -> old: %s, new: %s', line, old_start or 'nil', new_start or 'nil'))
		assert_eq(type(new_start), 'string', 'Should match hunk header: ' .. line)
	end
end)

print('\n' .. string.rep('=', 50))
print('Tests complete!')
