# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Type
This is a Flutter project.

## Testing Requirements
- **IMPORTANT**: After adding or updating any functionality, always add corresponding tests
- Maintain minimum 75% test coverage
- If coverage drops below 75%, prioritize adding tests before new features
- Run `make save` to ensure all quality checks pass before committing

## User Commands
- When user says "save" → run `make save` command
- This will format code, run lints, analyze types, run tests, check coverage, and commit

## Development Guidelines

### 1. Component Architecture
- Create reusable dumb components (stateless widgets when possible)
- Separate presentation logic from business logic
- Prefer composition over inheritance for widget reusability

### 2. Code Quality
- Keep functions small and focused on a single responsibility
- Keep code concise and readable
- Break down complex operations into smaller, testable units
- Aim for methods under 20 lines when feasible

### 3. Version Management
- Tag every finalized major functionality with version tags
- Maintain release notes for each version
- Use semantic versioning (e.g., v1.0.0, v1.1.0, v2.0.0)
- Tag format: `git tag -a v1.0.0 -m "Release description"`

## Project Structure Recommendations
- `/lib/widgets/` - Reusable UI components
- `/lib/screens/` - Screen/page widgets
- `/lib/models/` - Data models
- `/lib/services/` - Business logic and API services
- `/lib/utils/` - Helper functions and utilities