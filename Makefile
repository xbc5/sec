.PHONY: build clean install dev-install help

BINARY_NAME := sec
DIST_DIR := dist
BUILD_DIR := build
SPEC_FILE := sec.spec

help:
	@echo "Available targets:"
	@echo "  dev-install - Install PyInstaller and dev dependencies"
	@echo "  build       - Build hermetic binary using PyInstaller"
	@echo "  clean       - Remove build artifacts and dist directory"
	@echo "  install     - Install the binary to /usr/local/bin (requires sudo)"

dev-install:
	@echo "Installing development dependencies..."
	@uv sync --group dev
	@echo "Development dependencies installed."

build:
	@echo "Building hermetic binary with PyInstaller..."
	@uv run pyinstaller --clean --onefile --name $(BINARY_NAME) sec
	@echo "Build complete. Binary located at: $(DIST_DIR)/$(BINARY_NAME)"
	@echo "This binary can now be deployed independently."

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR) $(DIST_DIR) __pycache__ *.spec~
	@find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	@echo "Clean complete."

install:
	@if [ ! -f $(DIST_DIR)/$(BINARY_NAME) ]; then \
		echo "Error: Binary not found. Run 'make build' first."; \
		exit 1; \
	fi
	@echo "Installing $(BINARY_NAME) to /usr/local/bin/..."
	@sudo cp $(DIST_DIR)/$(BINARY_NAME) /usr/local/bin/$(BINARY_NAME)
	@sudo chmod +x /usr/local/bin/$(BINARY_NAME)
	@echo "Installation complete."
