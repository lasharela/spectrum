.PHONY: ios android clean test analyze format lint coverage save commit-safe

ios:
	flutter run -d iphone

android:
	flutter run -d android

clean:
	flutter clean

test:
	flutter test

analyze:
	flutter analyze

format:
	dart format .

lint:
	dart analyze --fatal-infos --fatal-warnings

coverage:
	flutter test --coverage
	@echo "Coverage report generated in coverage/lcov.info"

get:
	flutter pub get

build-ios:
	flutter build ios

build-apk:
	flutter build apk

doctor:
	flutter doctor

# Helper function to check if there are changes to commit
check-changes:
	@if [ -z "$$(git status --porcelain)" ]; then \
		echo "✅ No changes to commit"; \
		exit 0; \
	fi

# Comprehensive save command that ensures code quality before committing
save: format lint analyze test coverage
	@echo "════════════════════════════════════════════════════════════"
	@echo "🔍 Running comprehensive code quality checks..."
	@echo "════════════════════════════════════════════════════════════"
	@echo ""
	@echo "✅ Step 1/6: Code formatting completed"
	@echo "✅ Step 2/6: Lint checks passed"
	@echo "✅ Step 3/6: Static analysis passed"
	@echo "✅ Step 4/6: All tests passed"
	@echo "✅ Step 5/6: Test coverage generated"
	@echo ""
	@echo "📊 Checking test coverage..."
	@if [ -f coverage/lcov.info ]; then \
		lines=$$(grep -o "LF:[0-9]*" coverage/lcov.info | cut -d: -f2 | paste -sd+ | bc); \
		hits=$$(grep -o "LH:[0-9]*" coverage/lcov.info | cut -d: -f2 | paste -sd+ | bc); \
		if [ $$lines -gt 0 ]; then \
			coverage=$$(echo "scale=1; $$hits * 100 / $$lines" | bc); \
			echo "📈 Test coverage: $$coverage%"; \
			if [ $$(echo "$$coverage < 75" | bc) -eq 1 ]; then \
				echo "⚠️  Warning: Test coverage is below 75%!"; \
				echo "📝 Remember to add tests for new functionality"; \
			fi; \
		fi; \
	fi
	@echo ""
	@echo "💾 Step 6/6: Creating commit..."
	@git add -A
	@if [ -z "$$(git status --porcelain)" ]; then \
		echo "✅ No changes to commit - working tree clean"; \
	else \
		echo "Enter commit message (or press Enter for auto-generated):"; \
		read -r commit_msg; \
		if [ -z "$$commit_msg" ]; then \
			commit_msg="chore: auto-save with code quality checks"; \
			commit_msg="$$commit_msg\n\n- Code formatted with dart format"; \
			commit_msg="$$commit_msg\n- Passed lint checks"; \
			commit_msg="$$commit_msg\n- Passed static analysis"; \
			commit_msg="$$commit_msg\n- All tests passing"; \
			commit_msg="$$commit_msg\n\n🤖 Generated with make save"; \
		fi; \
		git commit -m "$$commit_msg"; \
		echo ""; \
		echo "✅ Changes committed successfully!"; \
	fi
	@echo ""
	@echo "════════════════════════════════════════════════════════════"
	@echo "✨ Save completed successfully!"
	@echo "════════════════════════════════════════════════════════════"

# Quick save without running tests (for WIP commits)
quick-save:
	@echo "🚀 Quick save (formatting only)..."
	@dart format .
	@git add -A
	@git commit -m "WIP: quick save" || echo "No changes to commit"

# Safe commit - ensures all checks pass but doesn't auto-commit
commit-safe: format lint analyze test
	@echo "✅ All checks passed! Safe to commit."
	@echo "Run 'git add -A && git commit -m \"your message\"' to commit."