ALL AI TOOLS MUST READ xmedit.md BEFORE MAKING CHANGES

# XMEdit Project Context

**Authoritative documentation for AI tools, developers, and maintainers.**

---

## 1. Project Overview

**XMEdit** is a Flutter desktop application for editing DHPO XML medical resubmission claim files.

**Problem Solved**: Manual correction of healthcare claim XML files before resubmission to avoid rejections. Streamlines editing claim details, activities, diagnoses, and resubmission metadata.

**Target Users**: Healthcare claim processors, medical billing staff handling claim corrections.

**Supported Platforms**: Windows (primary), macOS (with native menu bar), Web (limited).

**Current Version**: 4.1.0

---

## 2. Core Features

### Single-Claim XML Editor
- Load, edit, and save individual claim XML files
- Modify claim details (patient info, payer, provider, encounter data)
- Manage activities (add, delete, modify quantities, codes, nets)
- Manage diagnoses (add/delete ICD-10 codes, set principal diagnosis)
- Edit resubmission metadata (type, comment, PDF attachment)
- Observation CRUD with drag-and-drop file support

### Bulk XML (Multi-Claim) Editor
- Load XML files containing multiple claims (batch files)
- List view with search/filter capabilities
- Edit individual claims within bulk file
- **New**: Multi-select claims for batch deletion
- Preserve shared header metadata across all claims
- **New**: Split large XML files into chunks (max 2.95 MB) automatically
- Estimate file size for large batches

### Undo/Reset System
- **Single editor**: Reset to original loaded state (activities/diagnoses)
- **Bulk editor**: Undo stack (max 10 operations) + full reset to original

### Theme Support
- Material Design 3
- Light/Dark mode toggle
- Customizable seed color for dynamic color schemes

### Platform-Native Integration
- **macOS**: Native menu bar with CMD shortcuts, unified title bar with dynamic traffic light spacing
- **Windows**: Standard Flutter window with CTRL shortcuts
- Keyboard shortcuts (Open, Save, Save As) on both platforms

---

## 3. Architecture Overview

### Folder Structure
```
lib/
├── models/              # Data models (ClaimData, BulkClaimData, etc.)
├── providers/           # State management (ChangeNotifiers)
├── services/            # Business logic and I/O (XML, DB, logging)
├── pages/               # Top-level screens (single editor, bulk editor)
├── widgets/             # Reusable UI components
│   ├── bulk/           # Bulk editor-specific widgets
│   ├── cards/          # Single editor cards (totals, activities, etc.)
│   └── common/         # Shared utilities (custom table, inputs, etc.)
├── dialogs/            # Modal dialogs (add activity, diagnosis search)
├── utils/              # Helpers (attachment encoding/decoding)
├── database_helper.dart # SQLite interface for CPT/ICD-10 lookups
├── home_page.dart      # Main single-claim editor page
└── main.dart           # App entry point

macos/Runner/           # macOS-specific Swift code (native menus)
windows/runner/         # Windows-specific C++ code
```

### Responsibilities

- **`models/`**: Plain Dart classes representing XML structure. No business logic.
- **`providers/`**: `ChangeNotifier` subclasses managing app state, exposing methods for UI actions. Handle file I/O, XML parsing/generation via services.
- **`services/`**: Stateless logic for XML parsing/generation (using `xml` package), database queries (SQLite), logging, preferences, validation.
- **`pages/`**: Full-screen layouts orchestrating multiple widgets. Minimal logic—delegate to providers.
- **`widgets/`**: Reusable UI components. May be stateful for local UI state but rely on providers for app state.

**Separation of Concerns**: UI (widgets/pages) → State (providers) → Logic (services) → Data (models). Platform code (Swift/C++) isolated to native directories.

---

## 4. XML Handling Rules

### Detection: Single vs Bulk
- **Single XML**: Root element is `<Claim>` or `<ClaimRecord>` with one claim.
- **Bulk XML**: Root element contains multiple `<Claim>` children (detected by `detectBulkXml()` in `xml_service.dart`).
- If bulk XML loaded in single editor, user is prompted to open bulk editor instead.

### Parsing
- **Isolate-based parsing**: `parseXmlInBackground()` and `parseBulkXmlInBackground()` run in background isolates for large files (50KB+ per claim).
- Uses `xml` package (`^6.6.1`) for DOM parsing.
- Handles missing/optional fields gracefully (nullable strings).

### Modification
- Activities: Modify codes, quantities, nets, copays. Deleted activities marked with `isDeleted` flag (not removed from list to preserve indexes).
- Diagnoses: Add/delete ICD-10 codes. Enforce at least one principal diagnosis.
- Totals: Auto-calculate from activities or manual override.

### Saving
- **Single editor**: Generate XML via `generateXmlString()` in isolate. Save to Downloads directory (desktop) or trigger browser download (web).
- **Bulk editor**: Generate XML via `generateBulkXmlString()`. Preserve header metadata.
- **Formatting**: Output is formatted/indented XML with 2-space indentation.
- **Rename on save**: Optional feature to rename file based on claim ID (e.g., `claim_12345.xml`).

### Performance Considerations
- Files with 50+ claims may take 1-2 seconds to parse/generate.
- Deep cloning for undo uses optimized `clone()` methods (manual field copying, not reflection).

---

## 5. State Management

### Provider Pattern
- Uses `provider` package (`^6.1.5`) with `ChangeNotifier`.
- **Global providers** (via `MultiProvider` in `main.dart`):
  - `ClaimDataNotifier`: Single-claim editor state
  - `BulkClaimDataNotifier`: Bulk editor state
  - `ThemeNotifier`: Theme/color preferences
  - `CardVisibilityNotifier`: UI card collapse/expand state

### Undo/Redo Strategy
- **Single editor**: No undo stack. Only "Reset" to original loaded state (re-clones `_originalActivities` and `_originalDiagnoses`).
- **Bulk editor**: Stack-based undo (`List<BulkClaimData>`, max 10 items). Each destructive operation (delete claim) pushes snapshot. Reset clears stack and restores `_originalSnapshot`.

### Reset-to-Original Behavior
- On file load, original state stored as deep clone.
- Reset discards all edits, restores original, and clears undo stack.
- In bulk editor, "Reset" keeps file loaded; in single editor, "Clear All" unloads data.

### Performance & Memory
- Undo stack limited to 10 snapshots to prevent memory exhaustion with large bulk files.
- Deep clones manually copy fields (no serialization overhead).
- Only active claim data kept in memory; no caching of parsed XML trees.

---

## 6. UI & Design Rules

### Material Design Only
- **CRITICAL**: All UI uses Material 3 widgets (`MaterialApp`, `Scaffold`, `AppBar`, `Card`, `FilledButton`, etc.).
- **No Cupertino widgets** permitted, even on macOS. Platform-specific behavior is handled via logic, not UI toolkit.

### Consistent Design System
- **Spacing**: 8px base unit. Use `SizedBox(width: 8)`, `EdgeInsets.all(16)`, etc.
- **Colors**: Always use `Theme.of(context).colorScheme.*` for colors. No hardcoded hex colors.
- **Opacity**: Use `Color.withValues(alpha: value)` (NOT deprecated `withOpacity()`).
- **Typography**: Use `theme.textTheme.*` for text styles.
- **Borders**: Use `theme.colorScheme.outlineVariant` for borders.

### No Unsolicited UI Redesigns
- **DO NOT** change layouts, colors, or spacing without explicit user request.
- Maintain existing card structure, AppBar buttons, drawer navigation.
- Visual tweaks (icon changes, minor padding) permitted only if improving accessibility or fixing obvious bugs.

### Platform-Aware Layout Differences
- **AppBar title**: Wrapped in `DragToMoveArea` on desktop (not web) for window dragging.
- **Window controls**: Custom window buttons on macOS (minimize, maximize, close).
- **Menu bar**: Native macOS menu bar replaces in-app menu items.

---

## 7. Platform-Specific Behavior

### Windows
- Standard Flutter window with custom title bar (`bitsdojo_window`).
- Keyboard shortcuts use **CTRL** modifier (e.g., CTRL+O for Open).
- File picker uses native Windows dialogs.

### macOS
- **Native menu bar**: Defined in `NativeMenuService.dart` and implemented in Swift (`AppDelegate.swift`, `MainFlutterWindow.swift`).
- Menu items: File (Open, Save, Save As, Close Window), Edit (standard macOS edit commands).
- Keyboard shortcuts use **CMD** modifier (e.g., CMD+O for Open).
- Window chrome: Uses standard macOS window buttons (traffic lights).
- **Method channels**: `NativeMenuService` listens to `menu_action` channel for native menu callbacks.

### Platform Checks
- Use `kIsWeb` for web-specific logic (e.g., file download vs save dialog).
- Use `defaultTargetPlatform == TargetPlatform.macOS` for macOS-specific shortcuts.

### Constraints
- **Web**: Limited file system access. No native dialogs. Uses `universal_html` for downloads.
- **macOS/Windows**: Full file system access via `path_provider` and `file_picker`.

---

## 8. Coding Standards

### Dart Null-Safety
- **Strict null-safety enabled** (`sdk: '>=3.2.0 <4.0.0'`).
- Trust Dart's flow analysis. Avoid redundant `!= null` checks on non-nullable types.
- Use `String?` for optional fields, `String` for required.

### Import Hygiene
- Import only what you use.
- Prefer `package:flutter/foundation.dart` over `package:flutter/material.dart` for non-UI code.
- Use IDE tools to organize imports (remove unused, sort).

### No Deprecated APIs
- Replace deprecated Flutter APIs immediately (e.g., `withOpacity` → `withValues(alpha:)`).
- Run `dart fix --dry-run` to check for automated migrations.

### Analyzer Warnings Must Be Zero
- Run `flutter analyze` before commits.
- **Zero tolerance** for warnings. No `// ignore` comments except for unavoidable third-party issues.

### Preferred Patterns
- **String interpolation**: Use `'$variable'` not `'${variable}'` for simple variables.
- **Explicit types**: Always annotate callback parameters (e.g., `void callback(Duration _)`).
- **Immutable models**: Use `final` fields in model classes.

### Anti-Patterns
- ❌ Disabling lints in `analysis_options.yaml` to hide problems.
- ❌ Using `withOpacity()` instead of `withValues(alpha:)`.
- ❌ Importing `material.dart` when only `foundation.dart` is needed.
- ❌ Defensive null checks on variables promoted to non-nullable by flow analysis.

---

## 9. AI Contribution Rules

### What AI May Refactor
- ✅ Fix analyzer warnings, lints, deprecations.
- ✅ Improve code readability (extract methods, rename variables).
- ✅ Add null-safety improvements (remove redundant checks).
- ✅ Replace deprecated APIs with modern equivalents.
- ✅ Optimize performance (isolate usage, deep clone efficiency).
- ✅ Fix bugs reported by user.

### What AI Must NOT Change
- ❌ **UI layouts** without explicit request (no surprise redesigns).
- ❌ **Material Design → Cupertino** migration (Material only).
- ❌ **Provider architecture** → other state management (e.g., Bloc, Riverpod).
- ❌ **XML parsing logic** unless fixing bugs (high-risk area).
- ❌ **Database schema** (`database_helper.dart`) without migration plan.
- ❌ **Platform-specific code** (Swift/C++) unless testing on that platform.

### Introducing New Features Safely
1. **Discuss with user** before implementing.
2. **Follow existing patterns**: Use providers for state, services for logic, widgets for UI.
3. **Test both platforms** (Windows and macOS) if adding desktop features.
4. **Maintain backward compatibility**: Don't break existing XML file support.
5. **Document breaking changes**: Update this file if architecture changes.

### AI-Specific Guidelines
- Prefer **small, incremental changes** over large rewrites.
- If unsure about user intent, **ask clarifying questions** before making changes.
- Always run `flutter analyze` after changes.
- Test on **both light and dark themes** for UI changes.

---

### Mandatory Summary Updates

All AI tools MUST:
- Append a new entry to the AI Change Log for every code change
- Never rewrite or delete previous entries
- Treat the change log as append-only

Failure to update the log is considered an incomplete change.

---

## AI Change Log

**2026-01-20 22:16** - Implemented unified title bar for macOS and Windows
- **Changed**: macOS native window configuration (`.fullSizeContentView`, transparent title bar)
- **Changed**: `WindowButtons` widget now platform-aware (macOS reserves space, Windows uses `WindowCaption`)
- **Changed**: Both editors (`home_page.dart`, `bulk_editor_page.dart`) use transparent AppBar with macOS padding
- **Removed**: Custom-drawn window buttons from bulk editor (~35 lines)
- **Result**: Modern unified title bar with native OS controls visible and functional on both platforms
- **Files modified**: `MainFlutterWindow.swift`, `widgets.dart`, `home_page.dart`, `bulk_editor_page.dart`

**2026-01-20 22:23** - Optimized macOS title bar space usage
- **Removed**: App name and version from Flutter AppBar on macOS (redundant with OS menu bar)
- **Changed**: "About XMEdit" menu now shows version info from app bundle
- **Changed**: AppBar title is now empty on macOS (only drag area for traffic lights), shown on web
- **Result**: Significant vertical space savings on macOS, cleaner UI, version accessible via About menu
- **Files modified**: `AppDelegate.swift`, `home_page.dart`, `bulk_editor_page.dart`

**2026-01-20 22:50** - Phase 1 Full: Added XML Validation, UI Indicators, Shortcuts & Error Handling
- **Added**: `validation_result.dart` - Validation error model with severity levels (error/warning/info)
- **Added**: `validation_rules.dart` - 10+ DHPO-specific validation rules (ICD-10, dates, totals matching)
- **Added**: `xml_validator.dart` - Core validator orchestrating all rules
- **Added**: `validation_widgets.dart` - ValidationIndicator, ValidatedTextField, ValidationSummaryPanel
- **Added**: `error_dialog.dart` - Enhanced error dialogs with user-friendly messages and copy-to-clipboard
- **Added**: `shortcuts_help_dialog.dart` - Keyboard shortcuts help (F1) with 15+ shortcuts defined
- **Result**: Foundation for comprehensive validation system, improved error UX, keyboard navigation ready
- **Files created**: 6 new files in models/services/widgets
- **Next steps**: Integrate validation into providers, wire up keyboard shortcuts to actions

**2026-01-21 00:30** - Bulk Editor Enhancements & macOS Polish
- **Added**: Multi-select support with checkboxes in Bulk Editor list view
- **Added**: "Delete Selected" action in Bulk Editor
- **Added**: "Split Max 2.95MB" feature to automatically chunk large XML files
- **Changed**: Removed single-claim delete confirmation (now instant), kept batch confirmation
- **Changed**: "Reset" in Bulk Editor now correctly discards all changes and reloads file
- **Fixed**: macOS AppBar layout now correctly handles traffic lights in windowed vs full-screen modes
- **Fixed**: AppBar content no longer disappears in macOS full-screen mode
- **Added**: New high-resolution macOS App Icon (generated via script)
- **Files modified**: `bulk_editor_page.dart`, `home_page.dart`, `claim_data_notifier.dart`, `generate_icon.py`

**2026-01-21 00:45** - Deep Codebase Cleanup
- **Removed**: Deprecated/unused text controllers in `ClaimDataNotifier`
- **Removed**: Speculative comments and commented-out code blocks in providers and pages
- **Verified**: `flutter analyze` passing with zero issues
- **Formatted**: Codebase formatted with `dart format`
- **Files modified**: `claim_data_provider.dart`, `bulk_claim_data_provider.dart`, `bulk_editor_page.dart`

---

## 10. Build & Run

### Flutter Version
- **Required**: Flutter 3.x or higher (SDK 3.2.0+).
- Use stable channel: `flutter channel stable && flutter upgrade`.

### Dependencies Installation
```bash
flutter pub get
```

### Running the App
```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows

# Web (limited features)
flutter run -d chrome
```

### Building for Production

**macOS**:
```bash
flutter build macos --release
# Output: build/macos/Build/Products/Release/project_xmedit.app
```

**Windows**:
```bash
flutter build windows --release
# Output: build\windows\x64\runner\Release\
```

**MSIX Package (Windows only)**:
```bash
flutter pub run msix:create
# Requires msix package configuration in pubspec.yaml
```

### Database Setup
- SQLite databases for CPT codes and ICD-10 codes are initialized on first run.
- Asset files: `assets/code_descriptions.json`, `assets/icd10.json`.

---

## 11. Future-Proofing Notes

### Areas Intended for Expansion
- **Validation engine**: Currently minimal. Future: comprehensive DHPO XML schema validation.
- **Batch operations**: Future: Apply edits to multiple claims at once in bulk editor.
- **Templates**: Pre-configured resubmission templates for common correction scenarios.
- **Export formats**: Currently XML-only. Future: PDF reports, CSV exports.

### Known Constraints
- **Single undo in single editor**: Architectural limitation due to TextEditingController dependencies. Bulk editor has full undo.
- **Large files (500+ claims)**: May hit memory limits on low-end machines. Consider streaming XML parser in future.
- **Web platform**: File system limitations prevent full feature parity. Desktop-first design.

### Design Decisions to Respect
1. **Material 3 only**: Chosen for cross-platform consistency. Do not introduce Cupertino.
2. **Provider state management**: Well-suited for app's flat state structure. Do not migrate to Bloc/Riverpod without strong justification.
3. **Isolate-based XML parsing**: Required for large files (100KB+). Do not move to main thread.
4. **Deep cloning for undo**: Chosen for simplicity over serialization. Optimized enough for current scale.
5. **Platform channels for macOS menu**: Required for native feel. Do not replace with Flutter-only menus.

### Versioning Strategy
- **Major version** (4.x.x): Breaking XML format changes or major feature rewrites.
- **Minor version** (x.1.x): New features, bulk editor enhancements.
- **Patch version** (x.x.1): Bug fixes, analyzer compliance, dependency updates.

---

## Summary

XMEdit is a **desktop-first, Material 3, Flutter application** for editing healthcare claim XML files. It uses **Provider for state management**, **isolate-based XML processing** for performance, and **platform-specific integrations** (native macOS menus) for native feel.

**Core principles**:
- **Zero analyzer warnings** policy
- **Material Design only** (no Cupertino)
- **Desktop-first** (Windows/macOS primary, web limited)
- **Null-safe, modern Dart** patterns
- **Incremental changes** over rewrites

AI tools and developers must **respect existing architecture**, **maintain Material Design consistency**, and **test on both platforms** before proposing changes.

**This document is the authoritative source of truth for how XMEdit works.**
