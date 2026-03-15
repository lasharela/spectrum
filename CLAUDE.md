# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Spectrum is a mobile application designed as a social network for people with autism and their parents/caregivers. The app aims to create a supportive community platform with resources, communication tools, and social features tailored to the autism community's needs.

## Tech Stack

- **Frontend**: Flutter 3.32.5 / Dart 3.8.1
- **Backend**: Hono (TypeScript) on Cloudflare Workers
- **Database**: Cloudflare D1 (SQLite-based) with Prisma adapter
- **Auth**: Better Auth
- **State Management**: Riverpod
- **HTTP Client**: Dio
- **Navigation**: go_router
- **Forms**: flutter_form_builder with form_builder_validators
- **API Contracts**: OpenAPI 3.1.0 specs in `contracts/`
- **Testing**: Vitest (backend), flutter test (frontend), Vitest E2E (backend integration)

## Monorepo Structure

```
spectrum/
├── frontend/             # Flutter mobile app
│   ├── lib/
│   │   ├── core/         # Core functionality shared across features
│   │   │   ├── constants/
│   │   │   ├── router/
│   │   │   ├── themes/
│   │   │   └── utils/
│   │   ├── features/     # Feature modules (auth, home, community, etc.)
│   │   │   └── [feature]/
│   │   │       ├── data/
│   │   │       ├── domain/
│   │   │       └── presentation/
│   │   └── shared/
│   │       ├── services/
│   │       └── widgets/
│   ├── test/
│   ├── pubspec.yaml
│   └── analysis_options.yaml
├── backend/              # Hono API on Cloudflare Workers
│   ├── src/
│   ├── test/
│   ├── package.json
│   ├── tsconfig.json
│   └── wrangler.toml
├── contracts/            # OpenAPI specs (shared API contracts)
│   ├── auth.yaml
│   └── community.yaml
├── docs/                 # Documentation
├── package.json          # Root workspace config
├── pnpm-workspace.yaml
└── CLAUDE.md
```

## Commands

### Backend Development
```bash
# Start backend dev server
pnpm dev:backend

# Run backend tests
pnpm test:backend

# Generate Prisma client
pnpm --filter backend db:generate

# Run Prisma migrations
pnpm --filter backend db:migrate

# Push schema to database (no migration)
pnpm --filter backend db:push

# Open Prisma Studio
pnpm --filter backend db:studio

# Deploy to Cloudflare Workers
pnpm --filter backend deploy
```

### Backend E2E Tests

E2E tests run against a live dev server and test the full HTTP request/response cycle (auth, community, etc.). Logs and screenshots are saved to `backend/e2e/logs/` and `backend/e2e/screenshots/` — overwritten each run.

```bash
# 1. Start the dev server in one terminal
pnpm dev:backend

# 2. Run E2E tests in another terminal
pnpm --filter backend test:e2e
```

Output:
- `backend/e2e/logs/` — full request/response logs per test suite (JSON)
- `backend/e2e/screenshots/` — response snapshots per step (JSON)

> **Note:** E2E tests currently cover backend API flows only (auth lifecycle, sign-up, sign-in, session, sign-out). They require the dev server running on `http://localhost:8788`. Override with `E2E_BASE_URL` env var.

### Frontend Development
```bash
# Run the app
cd frontend && flutter run

# Run on specific device
cd frontend && flutter run -d [device_id]

# Hot reload (while app is running)
r

# Hot restart (while app is running)
R

# List available devices
flutter devices
```

### Frontend Dependencies
```bash
# Get dependencies
cd frontend && flutter pub get

# Upgrade dependencies
cd frontend && flutter pub upgrade

# Check outdated packages
cd frontend && flutter pub outdated
```

### Frontend Build
```bash
# Build for iOS
cd frontend && flutter build ios

# Build for Android
cd frontend && flutter build apk
cd frontend && flutter build appbundle

# Clean build artifacts
cd frontend && flutter clean
```

### Frontend Testing
```bash
# Run all tests
cd frontend && flutter test

# Run specific test file
cd frontend && flutter test test/[test_file.dart]

# Run tests with coverage
cd frontend && flutter test --coverage
```

### Workspace
```bash
# Install all dependencies (root)
pnpm install

# Clean all
pnpm clean
```

## Architecture

### Backend (Hono + Cloudflare Workers)

The backend follows a layered architecture:
- **Routes**: HTTP endpoint definitions (Hono routes)
- **Handlers**: Request/response handling logic
- **Services**: Business logic
- **Prisma Models**: Database schema and queries via Prisma adapter for D1
- **Auth**: Better Auth handles authentication (sessions, tokens)

### Frontend (Flutter + Riverpod)

The frontend follows a feature-based clean architecture pattern:

Each feature module is self-contained with its own:
- **Screens**: Full page views
- **Widgets**: Feature-specific components
- **Models**: Data structures
- **Providers**: Riverpod state management
- **Repositories**: Data access via Dio HTTP client

### API Contracts

OpenAPI 3.1.0 specs in `contracts/` define the interface between frontend and backend:
- `auth.yaml` - Authentication endpoints (sign-up, sign-in, sign-out, session)
- `community.yaml` - Community feed endpoints (posts, comments, reactions)

## Key Features to Implement

1. **Authentication System**
   - Email/password authentication via Better Auth
   - User type selection (parent, autistic_individual, professional, educator, therapist, supporter)
   - Profile management

2. **Community Features**
   - Post creation and sharing
   - Comments and reactions
   - User connections/friends
   - Group discussions

3. **Resources Section**
   - Educational content
   - Support resources
   - Event listings
   - Professional directory

4. **Accessibility Features**
   - Simple, clear UI design
   - Visual schedules
   - Communication aids
   - Sensory-friendly color schemes

## UI/UX Considerations

- Use calm, muted colors (defined in AppColors)
- Clear navigation with consistent patterns
- Large touch targets for better accessibility
- Visual feedback for all actions
- Minimize cognitive load with simple layouts
- Support for both light and dark themes
