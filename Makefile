.PHONY: test test-unit test-integration test-all analyze format check

# Unit + widget tests (no emulator needed)
test-unit:
	flutter test

# Integration tests (requires running emulator)
test-integration:
	@if adb devices 2>/dev/null | grep -q 'device$$'; then \
		JAVA_HOME=$$(mise where java@temurin-21.0.10+7.0.LTS) \
		flutter test integration_test/ -d $$(adb devices | grep device$$ | head -1 | cut -f1); \
	else \
		echo "No emulator/device found. Start one with: make emulator"; \
		exit 1; \
	fi

# All tests
test-all: test-unit test-integration

# Alias
test: test-all

# Static analysis
analyze:
	flutter analyze

# Format check
format:
	dart format --set-exit-if-changed .

# All checks (what you'd run before pushing)
check: format analyze test-all

# Start the emulator (background, headless)
emulator:
	@ANDROID_AVD_HOME=~/.config/.android/avd \
	JAVA_HOME=$$(mise where java@temurin-21.0.10+7.0.LTS) \
	emulator -avd mklat_test -no-audio -no-window -gpu swiftshader_indirect &
	@echo "Waiting for emulator to boot..."
	@adb wait-for-device
	@echo "Emulator ready."

# Regenerate test fixture constants (after updating .bin files)
fixtures:
	dart run tool/generate_test_fixtures.dart
