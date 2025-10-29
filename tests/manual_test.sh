#!/bin/bash
# Manual test script for chchchanges.nvim
# This creates a temporary test file with changes to verify the plugin works

set -e

cd "$(git rev-parse --show-toplevel)"

echo "Creating test file with changes..."

# Create a test file
cat > test_file.lua << 'EOF'
-- Test file for chchchanges
local M = {}

function M.test1()
  print("Original function")
end

function M.test2()
  return 42
end

return M
EOF

git add test_file.lua 2>/dev/null || true

# Modify the file to create unstaged changes
cat > test_file.lua << 'EOF'
-- Test file for chchchanges
local M = {}

function M.test1()
  print("Modified function")
  print("Added line")
end

function M.test2()
  return 100
end

function M.test3()
  print("New function")
end

return M
EOF

echo ""
echo "Test file created with unstaged changes."
echo ""
echo "Git diff output:"
echo "================"
git diff --no-ext-diff test_file.lua
echo "================"
echo ""
echo "Now run :ChChangesDebug in Neovim to see what the plugin sees"
echo "Or run :ChChanges to populate the quickfix list"
echo ""
echo "To clean up after testing, run: git checkout test_file.lua && rm test_file.lua"
