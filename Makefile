.PHONY: test manual-test clean

# Run automated tests
test:
	@echo "Running automated tests..."
	nvim --headless -c "luafile tests/parse_spec.lua" -c "qa!"

# Setup manual test environment
manual-test:
	@echo "Setting up manual test..."
	./tests/manual_test.sh

# Clean up test files
clean:
	@echo "Cleaning up test files..."
	git checkout test_file.lua 2>/dev/null || true
	rm -f test_file.lua
