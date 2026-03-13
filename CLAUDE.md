# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Spectrum is a Flutter mobile application designed as a social network for people with autism and their parents/caregivers. The app aims to create a supportive community platform with resources, communication tools, and social features tailored to the autism community's needs.

## Tech Stack

- **Frontend**: Flutter 3.32.5 / Dart 3.8.1
- **Backend**: Firebase (Firestore, Auth, Storage, Messaging, Analytics)
- **State Management**: Provider
- **Navigation**: go_router
- **Forms**: flutter_form_builder with form_builder_validators

## Commands

### Development
```bash
# Run the app
flutter run

# Run on specific device
flutter run -d [device_id]

# Hot reload (while app is running)
r

# Hot restart (while app is running)
R

# List available devices
flutter devices
```

### Dependencies
```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Check outdated packages
flutter pub outdated
```

### Build
```bash
# Build for iOS
flutter build ios

# Build for Android
flutter build apk
flutter build appbundle

# Clean build artifacts
flutter clean
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/[test_file.dart]

# Run tests with coverage
flutter test --coverage
```

### Firebase Setup
```bash
# Configure Firebase (requires Firebase project)
flutterfire configure

# Select platforms and link to Firebase project
# This generates lib/firebase_options.dart
```

## Architecture

The project follows a feature-based clean architecture pattern:

```
lib/
├── core/               # Core functionality shared across features
│   ├── constants/      # App-wide constants (colors, strings)
│   ├── router/         # Navigation configuration (go_router)
│   ├── themes/         # Material theme definitions
│   └── utils/          # Utility functions
├── features/           # Feature modules (auth, home, community, etc.)
│   └── [feature]/
│       ├── data/       # Data layer (models, repositories, datasources)
│       ├── domain/     # Domain layer (entities, repositories, usecases)
│       └── presentation/ # Presentation layer (screens, widgets)
└── shared/             # Shared components
    ├── services/       # Shared services (Firebase, API)
    └── widgets/        # Reusable widgets

Each feature module is self-contained with its own:
- **Screens**: Full page views
- **Widgets**: Feature-specific components
- **Models**: Data structures
- **Services**: Feature-specific business logic
```

## Key Features to Implement

1. **Authentication System**
   - Email/password authentication
   - User type selection (person with autism, parent, professional, supporter)
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

## Firebase Integration Notes

To complete Firebase setup:
1. Create a Firebase project at https://console.firebase.google.com
2. Run `flutterfire configure` to link the app
3. Uncomment Firebase initialization in `lib/main.dart`
4. Enable required Firebase services in console:
   - Authentication
   - Cloud Firestore
   - Cloud Storage
   - Cloud Messaging

## UI/UX Considerations

- Use calm, muted colors (already defined in AppColors)
- Clear navigation with consistent patterns
- Large touch targets for better accessibility
- Visual feedback for all actions
- Minimize cognitive load with simple layouts
- Support for both light and dark themes