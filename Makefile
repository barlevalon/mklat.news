.PHONY: test test-unit test-integration test-all analyze format check emulator

# Unit + widget tests (no emulator needed)
test-unit:
	flutter test

# Integration tests (auto-starts emulator if needed)
test-integration:
	@set -e; \
	device_id=$$(adb devices 2>/dev/null | awk '$$2 == "device" && $$1 != "List" { print $$1; exit }'); \
	if [ -z "$$device_id" ]; then \
		echo "No connected device found. Starting emulator..."; \
		$(MAKE) emulator; \
		device_id=$$(adb devices 2>/dev/null | awk '$$2 == "device" && $$1 != "List" { print $$1; exit }'); \
	fi; \
	if [ -z "$$device_id" ]; then \
		echo "Failed to find a connected device after emulator startup."; \
		exit 1; \
	fi; \
	echo "Running integration tests on $$device_id"; \
	JAVA_HOME=$$(mise where java@temurin-21.0.10+7.0.LTS) \
	flutter test integration_test/ -d "$$device_id"

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

# Start the emulator (background, headless, idempotent)
emulator:
	@set -e; \
	running_emulator=$$(adb devices 2>/dev/null | awk '$$2 == "device" && $$1 ~ /^emulator-/ { print $$1; exit }'); \
	if [ -n "$$running_emulator" ]; then \
		echo "Emulator already running: $$running_emulator"; \
		exit 0; \
	fi; \
	echo "Starting emulator mklat_test..."; \
	ANDROID_AVD_HOME=~/.config/.android/avd \
	JAVA_HOME=$$(mise where java@temurin-21.0.10+7.0.LTS) \
	nohup emulator -avd mklat_test -no-audio -no-window -gpu swiftshader_indirect > /tmp/mklat_test_emulator.log 2>&1 & \
	for attempt in $$(seq 1 60); do \
		emulator_id=$$(adb devices 2>/dev/null | awk '$$2 == "device" && $$1 ~ /^emulator-/ { print $$1; exit }'); \
		if [ -n "$$emulator_id" ]; then \
			echo "Waiting for $$emulator_id to finish booting..."; \
			adb -s "$$emulator_id" wait-for-device >/dev/null; \
			until [ "$$(adb -s "$$emulator_id" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do \
				sleep 2; \
			done; \
			echo "Emulator ready: $$emulator_id"; \
			exit 0; \
		fi; \
		sleep 2; \
	done; \
	echo "Timed out waiting for emulator to appear. See /tmp/mklat_test_emulator.log"; \
	exit 1

# Regenerate test fixture constants (after updating .bin files)
fixtures:
	dart run tool/generate_test_fixtures.dart
