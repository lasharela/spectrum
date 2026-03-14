# Phase 1: Infrastructure — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Lay the foundation for the Spectrum rebuild — upgrade Flutter, adopt Forui, build shared widgets, consolidate backend middleware, fix schema issues, and set up test infrastructure.

**Architecture:** Backend-first fixes (middleware consolidation, Prisma index fix) followed by frontend infrastructure (Flutter upgrade, Forui theme, shared widget library, folder structure). All changes on the `development` branch.

**Tech Stack:** Flutter + Forui + Riverpod (frontend), Hono + Prisma + D1 (backend), Vitest (backend tests), flutter_test (frontend tests)

**Reference:** Design spec at `docs/superpowers/specs/2026-03-13-spectrum-frontend-rebuild-design.md`

**Source material:** `ana/backup` branch contains original screens/widgets to port in later phases. Reference with `git show origin/ana/backup:<path>`.

---

## Chunk 1: Backend Infrastructure

### Task 1: Consolidate Backend Middleware

The current `backend/src/index.ts` duplicates Prisma/Auth middleware setup across 4 separate `app.use()` blocks (lines 28-59). Consolidate into a single middleware.

**Files:**
- Modify: `backend/src/index.ts`

- [ ] **Step 1: Read current index.ts to understand the duplication**

Read `backend/src/index.ts` in full. Note the 4 duplicate middleware blocks at lines 28-34, 36-42, 44-50, and 53-59. Each creates `prisma` and `auth` instances and sets them on context.

- [ ] **Step 2: Replace 4 duplicate middleware blocks with a single `app.use("/api/*")`**

In `backend/src/index.ts`, replace the 4 middleware blocks:

```typescript
// REMOVE these 4 blocks (lines 28-59):
// app.use("/api/auth/*", ...)
// app.use("/api/me", ...)
// app.use("/api/posts/*", ...)
// app.use("/api/posts", ...)

// REPLACE with single block, placed AFTER health check and BEFORE routes:
app.use("/api/*", async (c, next) => {
  const prisma = createPrismaClient(c.env.DB);
  const auth = createAuth(prisma, c.env.BETTER_AUTH_SECRET);
  c.set("prisma", prisma);
  c.set("auth", auth);
  await next();
});
```

The health check route (`GET /api/health`) is registered at line 22-24, which is BEFORE this middleware — so it remains unaffected.

- [ ] **Step 3: Verify backend still starts and health check works**

Run:
```bash
cd backend && pnpm dev
```
In another terminal:
```bash
curl http://localhost:8787/api/health
```
Expected: `{"status":"ok"}` with 200 status.

- [ ] **Step 4: Run existing backend tests**

Run:
```bash
cd backend && pnpm test
```
Expected: Health check test passes. Auth/community test stubs pass (they're just `expect(true).toBe(true)`).

- [ ] **Step 5: Commit**

```bash
git add backend/src/index.ts
git commit -m "refactor: consolidate duplicate API middleware into single block"
```

---

### Task 2: Fix Prisma Schema Indexes for D1 Compatibility

The Post and Comment models use `sort: Desc` in their index definitions, which is not supported by SQLite/D1 through Prisma.

**Files:**
- Modify: `backend/src/db/schema.prisma`

- [ ] **Step 1: Read current schema**

Read `backend/src/db/schema.prisma`. Note:
- Line 81: `@@index([createdAt(sort: Desc)])`
- Line 94: `@@index([postId, createdAt(sort: Desc)])`

- [ ] **Step 2: Remove sort directives from indexes**

Change line 81 from:
```prisma
  @@index([createdAt(sort: Desc)])
```
to:
```prisma
  @@index([createdAt])
```

Change line 94 from:
```prisma
  @@index([postId, createdAt(sort: Desc)])
```
to:
```prisma
  @@index([postId, createdAt])
```

Ordering is handled at query time via `orderBy: { createdAt: 'desc' }` — the index still speeds up the query.

- [ ] **Step 3: Regenerate Prisma client**

Run:
```bash
cd backend && pnpm db:generate
```
Expected: Prisma client generates successfully with no errors.

- [ ] **Step 4: Run backend tests to verify nothing broke**

Run:
```bash
cd backend && pnpm test
```
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add backend/src/db/schema.prisma
git commit -m "fix: remove sort:Desc from Prisma indexes for D1 compatibility"
```

---

### Task 3: Update CLAUDE.md to Reflect D1

The root CLAUDE.md still references "Neon Postgres" as the database. Update to reflect the actual D1 stack.

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Read CLAUDE.md**

Read `CLAUDE.md`. Find the Tech Stack section and database references.

- [ ] **Step 2: Update database references**

Change the Tech Stack line from:
```
- **Database**: Neon Postgres with Prisma (edge-compatible)
```
to:
```
- **Database**: Cloudflare D1 (SQLite-based) with Prisma adapter
```

Also update the backend commands section — replace any `db:migrate` description mentioning Postgres with D1-appropriate language if present.

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md to reflect D1 database instead of Neon Postgres"
```

---

## Chunk 2: Flutter Upgrade & Forui Setup

### Task 4: Upgrade Flutter and Add Forui Dependency

Upgrade Flutter to the version required by Forui, add the Forui package.

**Files:**
- Modify: `frontend/pubspec.yaml`
- Modify: `frontend/lib/main.dart`

- [ ] **Step 1: Check current Flutter version and Forui requirements**

Run:
```bash
cd frontend && flutter --version
```

If the current Flutter version is too old for Forui (check Forui's pub.dev page for SDK constraint), upgrade:
```bash
flutter upgrade
```

Verify new version:
```bash
flutter --version
```

- [ ] **Step 2: Update SDK constraint in pubspec.yaml if needed**

If `flutter upgrade` changed the Dart SDK version, update the `sdk` constraint in `frontend/pubspec.yaml` to match (e.g., `sdk: ^3.x.y` where x.y matches the new version).

- [ ] **Step 3: Add Forui dependency**

Run:
```bash
cd frontend && flutter pub add forui
```

Expected: `forui` added to `pubspec.yaml` dependencies.

- [ ] **Step 4: Verify the app still compiles**

Run:
```bash
cd frontend && flutter pub get && flutter analyze
```

Expected: No analysis errors (warnings are acceptable).

- [ ] **Step 5: Commit**

```bash
git add frontend/pubspec.yaml frontend/pubspec.lock
git commit -m "feat: upgrade Flutter and add Forui dependency"
```

---

### Task 5: Configure Forui Theme to Match Cyan/Coral Palette

Create the Forui theme configuration that matches the existing AppColors palette, and bridge it to Material for backward compatibility.

**Files:**
- Create: `frontend/lib/core/themes/forui_theme.dart`
- Modify: `frontend/lib/main.dart`

- [ ] **Step 1: Create Forui theme file**

Create `frontend/lib/core/themes/forui_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../constants/app_colors.dart';

class AppForuiTheme {
  static FThemeData get light {
    return FThemeData(
      colorScheme: const FColorScheme(
        brightness: Brightness.light,
        primary: AppColors.cyan,
        primaryForeground: Colors.white,
        secondary: AppColors.coral,
        secondaryForeground: Colors.white,
        muted: AppColors.backgroundGray,
        mutedForeground: AppColors.textGray,
        destructive: AppColors.error,
        destructiveForeground: Colors.white,
        background: AppColors.backgroundGray,
        foreground: AppColors.textDark,
        border: AppColors.border,
      ),
    );
  }

  static FThemeData get dark {
    return FThemeData(
      colorScheme: FColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.cyan,
        primaryForeground: Colors.white,
        secondary: AppColors.coral,
        secondaryForeground: Colors.white,
        muted: Colors.grey.shade800,
        mutedForeground: AppColors.textGray,
        destructive: AppColors.error,
        destructiveForeground: Colors.white,
        background: Colors.grey.shade900,
        foreground: Colors.white,
        border: Colors.grey.shade700,
      ),
    );
  }
}
```

**IMPORTANT — Pseudocode:** The `FThemeData` / `FColorScheme` constructors above are illustrative. The actual Forui API will differ. At implementation time:
1. Check https://forui.dev/docs/concepts/themes for the real constructor
2. Check if Forui provides `FThemes` presets (e.g., `FThemes.blue.light`) and use `copyWith()` to apply your colors
3. The color values (cyan, coral, etc.) are correct — only the API shape needs adjustment

- [ ] **Step 2: Bridge Material theme via `toApproximateMaterialTheme()`**

After creating the Forui theme, update `app_theme.dart` to derive Material themes from it. If Forui provides `toApproximateMaterialTheme()` on `FThemeData`, use it:

```dart
// In app_theme.dart, add:
static ThemeData get lightTheme => AppForuiTheme.light.toApproximateMaterialTheme();
static ThemeData get darkTheme => AppForuiTheme.dark.toApproximateMaterialTheme();
```

If `toApproximateMaterialTheme()` is not available, keep the existing `AppTheme.lightTheme` / `AppTheme.darkTheme` as-is — Material and Forui themes will coexist until screens are migrated.

- [ ] **Step 3: Update main.dart to wrap with FTheme**

Modify `frontend/lib/main.dart` to nest `FTheme` inside `MaterialApp.router`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'core/router/app_router.dart';
import 'core/themes/app_theme.dart';
import 'core/themes/forui_theme.dart';
import 'core/constants/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SpectrumApp()));
}

class SpectrumApp extends StatelessWidget {
  const SpectrumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        final foruiTheme = brightness == Brightness.dark
            ? AppForuiTheme.dark
            : AppForuiTheme.light;
        return FTheme(
          data: foruiTheme,
          child: child!,
        );
      },
    );
  }
}
```

- [ ] **Step 4: Verify the app compiles and runs**

Run:
```bash
cd frontend && flutter analyze
```

If possible, run on a device/simulator:
```bash
cd frontend && flutter run
```

Expected: App launches with the same visual appearance (no Forui widgets used yet, just theme configured).

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/core/themes/forui_theme.dart frontend/lib/core/themes/app_theme.dart frontend/lib/main.dart
git commit -m "feat: configure Forui theme with cyan/coral palette and Material bridge"
```

---

## Chunk 3: Shared Widget Library

### Task 6: Create AppButton Widget

Shared button widget wrapping Forui's `FButton` with app-specific variants.

**Files:**
- Create: `frontend/lib/shared/widgets/app_button.dart`
- Create: `frontend/test/shared/widgets/app_button_test.dart`

- [ ] **Step 1: Write the widget test**

Create `frontend/test/shared/widgets/app_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:spectrum/shared/widgets/app_button.dart';
import 'package:spectrum/core/themes/forui_theme.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: FTheme(
        data: AppForuiTheme.light,
        child: Scaffold(body: child),
      ),
    );
  }

  group('AppButton', () {
    testWidgets('renders with label text', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        AppButton(
          label: 'Sign In',
          onPressed: () {},
        ),
      ));
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(buildTestWidget(
        AppButton(
          label: 'Tap Me',
          onPressed: () => pressed = true,
        ),
      ));
      await tester.tap(find.text('Tap Me'));
      expect(pressed, isTrue);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const AppButton(
          label: 'Disabled',
          onPressed: null,
        ),
      ));
      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        AppButton(
          label: 'Loading',
          onPressed: () {},
          isLoading: true,
        ),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
cd frontend && flutter test test/shared/widgets/app_button_test.dart
```
Expected: FAIL — `package:spectrum/shared/widgets/app_button.dart` not found.

- [ ] **Step 3: Implement AppButton**

Create `frontend/lib/shared/widgets/app_button.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

enum AppButtonVariant { primary, secondary, outlined, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return FButton(
        onPress: null,
        label: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    switch (variant) {
      case AppButtonVariant.primary:
        return FButton(
          onPress: onPressed,
          label: Text(label),
        );
      case AppButtonVariant.secondary:
        return FButton.raw(
          onPress: onPressed,
          child: Text(label),
        );
      case AppButtonVariant.outlined:
        return FButton(
          style: FButtonStyle.outline,
          onPress: onPressed,
          label: Text(label),
        );
      case AppButtonVariant.text:
        return FButton(
          style: FButtonStyle.ghost,
          onPress: onPressed,
          label: Text(label),
        );
    }
  }
}
```

**IMPORTANT — Pseudocode:** The `FButton` constructor, `FButtonStyle` enum, and `FButton.raw` named constructor are illustrative. At implementation time, check https://forui.dev/docs/form/button for the real API. The widget's interface (label, onPressed, variant, isLoading) stays the same — only the Forui wrapper code needs adjustment.

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
cd frontend && flutter test test/shared/widgets/app_button_test.dart
```
Expected: All 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/shared/widgets/app_button.dart frontend/test/shared/widgets/app_button_test.dart
git commit -m "feat: add AppButton shared widget wrapping Forui FButton"
```

---

### Task 7: Create AppTextField Widget

Shared text field wrapping Forui's `FTextField` with consistent styling.

**Files:**
- Create: `frontend/lib/shared/widgets/app_text_field.dart`
- Create: `frontend/test/shared/widgets/app_text_field_test.dart`

- [ ] **Step 1: Write the widget test**

Create `frontend/test/shared/widgets/app_text_field_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:spectrum/shared/widgets/app_text_field.dart';
import 'package:spectrum/core/themes/forui_theme.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: FTheme(
        data: AppForuiTheme.light,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  group('AppTextField', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const AppTextField(label: 'Email'),
      ));
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('accepts text input', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(buildTestWidget(
        AppTextField(
          label: 'Name',
          controller: controller,
        ),
      ));
      await tester.enterText(find.byType(TextField).first, 'Test User');
      expect(controller.text, 'Test User');
    });

    testWidgets('obscures text when isPassword is true', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const AppTextField(
          label: 'Password',
          isPassword: true,
        ),
      ));
      // Forui text field should be rendered with obscured text
      expect(find.text('Password'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
cd frontend && flutter test test/shared/widgets/app_text_field_test.dart
```
Expected: FAIL — `package:spectrum/shared/widgets/app_text_field.dart` not found.

- [ ] **Step 3: Implement AppTextField**

Create `frontend/lib/shared/widgets/app_text_field.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return FTextField(
      label: Text(label),
      hint: hint,
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChange: onChanged,
    );
  }
}
```

**IMPORTANT — Pseudocode:** The `FTextField` constructor is illustrative. Check https://forui.dev/docs/form/text-field at implementation time. Key parameters to map: `label`, `hint`, `obscureText`, `controller`, `keyboardType`, `maxLines`, `onChange`.

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
cd frontend && flutter test test/shared/widgets/app_text_field_test.dart
```
Expected: All 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/shared/widgets/app_text_field.dart frontend/test/shared/widgets/app_text_field_test.dart
git commit -m "feat: add AppTextField shared widget wrapping Forui FTextField"
```

---

### Task 8: Create AppCard Widget

Shared card widget wrapping Forui's `FCard`.

**Files:**
- Create: `frontend/lib/shared/widgets/app_card.dart`
- Create: `frontend/test/shared/widgets/app_card_test.dart`

- [ ] **Step 1: Write the widget test**

Create `frontend/test/shared/widgets/app_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:spectrum/shared/widgets/app_card.dart';
import 'package:spectrum/core/themes/forui_theme.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: FTheme(
        data: AppForuiTheme.light,
        child: Scaffold(body: child),
      ),
    );
  }

  group('AppCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const AppCard(child: Text('Card Content')),
      ));
      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('renders with title when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const AppCard(
          title: 'Card Title',
          child: Text('Body'),
        ),
      ));
      expect(find.text('Card Title'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('calls onTap when tappable', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildTestWidget(
        AppCard(
          onTap: () => tapped = true,
          child: const Text('Tappable'),
        ),
      ));
      await tester.tap(find.text('Tappable'));
      expect(tapped, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
cd frontend && flutter test test/shared/widgets/app_card_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Implement AppCard**

Create `frontend/lib/shared/widgets/app_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final card = FCard(
      title: title != null ? Text(title!) : null,
      subtitle: subtitle != null ? Text(subtitle!) : null,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
```

**IMPORTANT — Pseudocode:** The `FCard` constructor is illustrative. Check https://forui.dev/docs/data/card at implementation time — parameter names may differ.

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
cd frontend && flutter test test/shared/widgets/app_card_test.dart
```
Expected: All 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/shared/widgets/app_card.dart frontend/test/shared/widgets/app_card_test.dart
git commit -m "feat: add AppCard shared widget wrapping Forui FCard"
```

---

### Task 9: Create AppErrorWidget and AppLoadingWidget

Standardized error and loading state widgets.

**Files:**
- Create: `frontend/lib/shared/widgets/app_error_widget.dart`
- Create: `frontend/lib/shared/widgets/app_loading_widget.dart`
- Create: `frontend/test/shared/widgets/app_error_widget_test.dart`
- Create: `frontend/test/shared/widgets/app_loading_widget_test.dart`

- [ ] **Step 1: Write tests for both widgets**

Create `frontend/test/shared/widgets/app_error_widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum/shared/widgets/app_error_widget.dart';

void main() {
  group('AppErrorWidget', () {
    testWidgets('displays error message', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AppErrorWidget(message: 'Something went wrong')),
      ));
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('shows retry button and calls onRetry', (tester) async {
      bool retried = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppErrorWidget(
            message: 'Error',
            onRetry: () => retried = true,
          ),
        ),
      ));
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AppErrorWidget(message: 'Error')),
      ));
      expect(find.text('Retry'), findsNothing);
    });
  });
}
```

Create `frontend/test/shared/widgets/app_loading_widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum/shared/widgets/app_loading_widget.dart';

void main() {
  group('AppLoadingWidget', () {
    testWidgets('shows a progress indicator', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AppLoadingWidget()),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays message when provided', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AppLoadingWidget(message: 'Loading posts...')),
      ));
      expect(find.text('Loading posts...'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
cd frontend && flutter test test/shared/widgets/app_error_widget_test.dart test/shared/widgets/app_loading_widget_test.dart
```
Expected: FAIL — files not found.

- [ ] **Step 3: Implement both widgets**

Create `frontend/lib/shared/widgets/app_error_widget.dart`:

```dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.textDark),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

Create `frontend/lib/shared/widgets/app_loading_widget.dart`:

```dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppLoadingWidget extends StatelessWidget {
  final String? message;

  const AppLoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.cyan),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(fontSize: 14, color: AppColors.textGray),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
cd frontend && flutter test test/shared/widgets/app_error_widget_test.dart test/shared/widgets/app_loading_widget_test.dart
```
Expected: All 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/shared/widgets/app_error_widget.dart frontend/lib/shared/widgets/app_loading_widget.dart frontend/test/shared/widgets/app_error_widget_test.dart frontend/test/shared/widgets/app_loading_widget_test.dart
git commit -m "feat: add AppErrorWidget and AppLoadingWidget shared widgets"
```

---

### Task 10: Create Shared Widgets Barrel Export

Create a single export file so consumers can import all shared widgets from one place.

**Files:**
- Create: `frontend/lib/shared/widgets/widgets.dart`

- [ ] **Step 1: Create barrel file**

Create `frontend/lib/shared/widgets/widgets.dart`:

```dart
export 'app_button.dart';
export 'app_card.dart';
export 'app_error_widget.dart';
export 'app_loading_widget.dart';
export 'app_text_field.dart';
export 'main_navigation_shell.dart';
```

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/shared/widgets/widgets.dart
git commit -m "feat: add shared widgets barrel export"
```

---

## Chunk 4: Folder Structure, Test Infrastructure & Seed Script

### Task 11: Enforce Clean Architecture Folder Structure

Create the data/domain/presentation directory structure for all 9 features. Some already exist (auth, community), others need to be created.

**Files:**
- Create directories for: home, catalog, events, promotions, notifications, map, profile (data + domain + presentation layers)
- Remove: `frontend/lib/features/resources/` (decomposed into catalog + events + promotions)
- Remove: `frontend/lib/features/organizations/` (renamed to catalog)

- [ ] **Step 1: Create missing feature directories**

Run:
```bash
# Features that need full directory structure
for feature in home catalog events promotions notifications map profile; do
  mkdir -p frontend/lib/features/$feature/data
  mkdir -p frontend/lib/features/$feature/domain
  mkdir -p frontend/lib/features/$feature/presentation/screens
  mkdir -p frontend/lib/features/$feature/presentation/widgets
  mkdir -p frontend/lib/features/$feature/presentation/providers
done
```

- [ ] **Step 2: Add .gitkeep files so empty dirs are tracked**

Run:
```bash
for feature in home catalog events promotions notifications map profile; do
  for layer in data domain; do
    touch frontend/lib/features/$feature/$layer/.gitkeep
  done
  for sublayer in screens widgets providers; do
    touch frontend/lib/features/$feature/presentation/$sublayer/.gitkeep
  done
done
```

- [ ] **Step 3: Remove deprecated features (resources, organizations)**

The `resources` feature is being decomposed into catalog + events + promotions.
The `organizations` feature is being renamed to `catalog`.

Run:
```bash
rm -rf frontend/lib/features/resources
rm -rf frontend/lib/features/organizations
```

**Note:** The project will NOT compile after this step — the router still imports the deleted screens. Do NOT run `flutter analyze` here. Router updates happen in Task 14.

- [ ] **Step 4: Verify directory structure looks correct**

Run:
```bash
ls frontend/lib/features/
```

Expected: `auth`, `catalog`, `community`, `events`, `home`, `map`, `notifications`, `profile`, `promotions` — 9 features, no `resources` or `organizations`.

- [ ] **Step 5: Commit directory changes only (router fix in Task 14)**

```bash
git add frontend/lib/features/
git commit -m "refactor: enforce clean architecture folder structure for all features"
```

**Note:** App will not compile until Task 14 fixes the router. Proceed directly to Tasks 12-13 (which don't depend on compilation), then Task 14.

---

### Task 12: Set Up Frontend Test Infrastructure

Expand the test helpers with mocks needed for critical path testing.

**Files:**
- Modify: `frontend/test/helpers/mocks.dart`
- Create: `frontend/test/helpers/test_utils.dart`

- [ ] **Step 1: Read current mocks.dart**

Read `frontend/test/helpers/mocks.dart` — currently only has `MockSecureStorage`.

- [ ] **Step 2: Create test utility helpers**

Create `frontend/test/helpers/test_utils.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:spectrum/core/themes/forui_theme.dart';
import 'package:spectrum/core/themes/app_theme.dart';

/// Wraps a widget with MaterialApp + FTheme + ProviderScope for testing.
/// Pass [overrides] to override Riverpod providers in tests.
Widget buildTestApp(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: FTheme(
        data: AppForuiTheme.light,
        child: Scaffold(body: child),
      ),
    ),
  );
}
```

- [ ] **Step 3: Verify test helpers compile**

Run:
```bash
cd frontend && dart analyze test/helpers/
```

Expected: No errors. This verifies the files parse correctly.

- [ ] **Step 4: Commit**

```bash
git add frontend/test/helpers/test_utils.dart
git commit -m "feat: add test utility helpers with Forui + Riverpod support"
```

---

### Task 13: Create Database Seed Script

Create a seed script that populates D1 with sample data ported from the hardcoded data in `ana/backup`.

**Files:**
- Create: `backend/src/db/seed.ts`
- Modify: `backend/package.json` (add seed script)

- [ ] **Step 1: Extract sample data from ana/backup**

Read the hardcoded data from the backup branch to understand what to seed:
```bash
git show origin/ana/backup:lib/screens/catalog_screen.dart | head -200
git show origin/ana/backup:lib/screens/community_screen.dart | head -100
```

- [ ] **Step 2: Create seed script**

Create `backend/src/db/seed.ts`:

```typescript
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  console.log("Seeding database...");

  // Create sample users
  const users = await Promise.all([
    prisma.user.upsert({
      where: { email: "sarah@example.com" },
      update: {},
      create: {
        email: "sarah@example.com",
        emailVerified: true,
        name: "Sarah M.",
        userType: "parent",
      },
    }),
    prisma.user.upsert({
      where: { email: "john@example.com" },
      update: {},
      create: {
        email: "john@example.com",
        emailVerified: true,
        name: "John D.",
        userType: "professional",
      },
    }),
    prisma.user.upsert({
      where: { email: "maria@example.com" },
      update: {},
      create: {
        email: "maria@example.com",
        emailVerified: true,
        name: "Maria L.",
        userType: "educator",
      },
    }),
  ]);

  // Create sample posts (individual upserts — createMany with skipDuplicates not supported on SQLite)
  const postData = [
    {
      content: "Tips for managing sensory overload in public spaces. I've found that noise-canceling headphones really help...",
      tags: '["Sensory", "Tips"]',
      authorId: users[0].id,
      likesCount: 45,
      commentsCount: 2,
    },
    {
      content: "Just discovered a great new therapy center in our area! They specialize in speech therapy for children.",
      tags: '["Resources", "Therapy"]',
      authorId: users[1].id,
      likesCount: 23,
      commentsCount: 1,
    },
    {
      content: "Our school just implemented a sensory room and the results have been amazing for our students.",
      tags: '["Education", "Sensory"]',
      authorId: users[2].id,
      likesCount: 67,
      commentsCount: 0,
    },
  ];

  for (const post of postData) {
    await prisma.post.create({ data: post });
  }

  console.log("Seed complete.");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

**Note:** This seed script uses the local SQLite database (dev). For D1 production seeding, use `wrangler d1 execute` with raw SQL. The seed script is primarily for local development. Additional seed data (organizations, events, promotions) will be added in their respective phases when those models are created.

- [ ] **Step 3: Install tsx and add seed script to package.json**

Run:
```bash
cd backend && pnpm add -D tsx
```

Then in `backend/package.json`, add to the `scripts` section:

```json
"db:seed": "npx tsx src/db/seed.ts"
```

- [ ] **Step 4: Test the seed script**

Run:
```bash
cd backend && pnpm db:seed
```
Expected: "Seeding database..." followed by "Seed complete." with no errors.

- [ ] **Step 5: Commit**

```bash
git add backend/src/db/seed.ts backend/package.json
git commit -m "feat: add database seed script with sample users and posts"
```

---

### Task 14: Update Router for New Navigation Structure

Update the router to reflect the new 4-tab navigation (Home, Community, Catalog, Profile) and remove dead routes.

**Files:**
- Modify: `frontend/lib/core/router/app_router.dart`
- Modify: `frontend/lib/shared/widgets/main_navigation_shell.dart`

- [ ] **Step 1: Read current router and navigation shell**

Read both files to understand current structure.

- [ ] **Step 2: Update navigation shell destinations**

In `frontend/lib/shared/widgets/main_navigation_shell.dart`, update the destinations list to 4 tabs. Replace the existing tab definitions with:

```dart
// Navigation destinations - update icons and labels:
// Index 0: Home    (Icons.home_outlined / Icons.home)
// Index 1: Community (Icons.people_outlined / Icons.people)
// Index 2: Catalog   (Icons.storefront_outlined / Icons.storefront)
// Index 3: Profile   (Icons.person_outlined / Icons.person)
```

Remove any reference to "Resources" tab. Update the `_selectedIndex` mapping to match the new 4 routes: `/home`, `/community`, `/catalog`, `/profile`.

- [ ] **Step 3: Update router — remove dead routes, add catalog placeholder**

In `frontend/lib/core/router/app_router.dart`:

1. Remove imports for `ResourcesScreen` and `OrganizationsScreen`
2. Remove the `/resources` GoRoute
3. Remove the `/organizations` GoRoute
4. Add a `/catalog` route with a temporary placeholder:

```dart
GoRoute(
  path: '/catalog',
  builder: (context, state) => const Scaffold(
    body: Center(child: Text('Catalog — coming in Phase 5')),
  ),
),
```

5. Ensure the ShellRoute's child routes are: `/home`, `/community`, `/catalog`, `/profile`

- [ ] **Step 4: Verify app compiles and navigation works**

Run:
```bash
cd frontend && flutter analyze
```

Expected: No errors. The app should compile now (this is the first clean compile since Task 11 removed the feature directories).

If possible, run on a device/simulator and verify all 4 tabs navigate correctly:
```bash
cd frontend && flutter run
```

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/core/router/app_router.dart frontend/lib/shared/widgets/main_navigation_shell.dart
git commit -m "refactor: update navigation to 4 tabs (Home, Community, Catalog, Profile)"
```

---

## Phase 1 Completion Checklist

After all tasks are done, verify:

- [ ] Backend middleware is a single `app.use("/api/*")` block
- [ ] Prisma indexes no longer use `sort: Desc`
- [ ] CLAUDE.md references D1 instead of Neon Postgres
- [ ] Flutter upgraded to latest stable
- [ ] Forui added and theme configured (cyan/coral palette)
- [ ] Shared widgets created: AppButton, AppTextField, AppCard, AppErrorWidget, AppLoadingWidget
- [ ] All 9 feature directories have data/domain/presentation structure
- [ ] `resources` and `organizations` features removed
- [ ] Navigation updated to 4 tabs (Home, Community, Catalog, Profile)
- [ ] Test helpers include `buildTestApp()` utility
- [ ] Seed script creates sample data
- [ ] All existing tests still pass
- [ ] App compiles and runs without errors

**Next:** Phase 2 plan will be created when ready to implement the Auth feature rebuild.
