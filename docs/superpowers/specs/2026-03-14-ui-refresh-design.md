# UI Refresh — Match ana/backup Original Design

## Goal

Refresh the entire frontend UI to match the original `ana/backup` branch design. The `temp/` screenshots are the target. Fix spacing, colors, components, and make everything consistent and modern.

## Changes

### 1. Color Palette (switch to original)

| Token | Current | Target (ana/backup) |
|-------|---------|-------------------|
| Primary | `#4ECDC4` (cyan) | `#262CD9` (dark blue) |
| Secondary | `#FF6B6B` (coral) | `#C8A9F2` (light purple) |
| Background | `#F0F4F8` (blue-gray) | `#F4EFEA` (warm cream) |
| Card BG | `#FFFFFF` | `#FFFFFF` |
| Text Primary | `#2E3A59` (navy) | `#383838` (dark gray) |
| Text Secondary | `#8B95A7` | `#7F8C8D` |
| Accent/Orange | `#FF8C42` | `#F2A100` (amber) |
| Error | `#FF5252` | `#D8032C` |
| Success | `#4CAF50` | `#1E9A64` |
| Border | `#E8ECF0` | `#E8EAED` |
| Tertiary | N/A | `#6FC2FF` (light blue) |

### 2. Spacing Constants (`AppSpacing`)

New file: `frontend/lib/core/constants/app_spacing.dart`
- `xxs: 4`, `xs: 6`, `sm: 8`, `md: 12`, `lg: 16`, `xl: 20`, `xxl: 24`, `xxxl: 32`
- `screenPadding: 20` (consistent outer padding for all screens)

### 3. Reusable Screen Scaffold

`SpectrumAppBar` widget:
- Leading: bell icon (no red dot), proper 16px padding from edge
- Center: screen title (bold)
- Trailing: settings gear, proper 16px padding from edge
- Consistent across all screens

### 4. Home Screen

- Match original greeting card style (white, bordered, subtle shadow)
- Quick Actions: 3 equal-width cards matching original (not 4-column grid)
- Promotions section: horizontal cards with gradient, discount badge
- Places section: cards with icon circle (50x50), name, address, "Get directions" button
- Events section: cards with icon, title, time, location, category badge
- Add temporary mock data in backend for all sections

### 5. Community Page (major fix)

Match `ana/backup` exactly:
- Post cards: author avatar (circle), name, timestamp, category badge (gold/amber background), title (bold), preview text, image placeholder area, like/comment/share action row
- New Discussion modal: full-page style with Cancel/Post header, category chips, Title field, Content field, Add Image section
- FAB: round dark blue circle with white + icon
- Search bar: matches original styling
- Tab bar: clean underline indicator

### 6. Post Detail

Match `ana/backup`:
- Author header with avatar, name, timestamp, category badge
- Full post content
- Divider
- "Replies" section with count
- Reply cards with avatar, name, timestamp, content
- Reply input at bottom with send button

### 7. Cards & Shadows

All cards follow original pattern:
- White background
- Border: `1px #E8EAED`
- Shadow: `0 2px 8px rgba(0,0,0,0.05)`
- Border radius: 12-16px
- Padding: 16px

### 8. Bottom Navigation

- Keep 5 tabs (Home, Community, Catalogue, Promotions, Events)
- Selected state: primary blue color
- Match original styling

### 9. FAB (all screens)

- Perfectly round (CircleShape)
- Dark blue (`#262CD9`) background
- White + icon
- Not square/rounded-square

### 10. Backend Mock Data

Add temporary mock data to `/api/dashboard` response:
- 3 promotions with titles, store names, discounts
- 3 places with names, addresses, ratings
- 3 events with titles, dates, locations, categories

## Out of Scope

- New features (image upload, maps, etc.)
- Auth screen redesign
- Backend logic changes beyond mock data
