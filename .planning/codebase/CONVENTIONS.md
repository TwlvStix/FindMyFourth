# Code Conventions

## Import Style

- **Project files**: Absolute imports with leading slash — `import '/models/game.dart'`
- **External packages**: Standard package imports — `import 'package:firebase_auth/firebase_auth.dart'`
- **Organization**: External packages first, then absolute imports grouped by feature area

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Files | `snake_case` | `game_service.dart`, `vibe_scoring_test.dart` |
| Classes | `PascalCase` | `GameService`, `GamesListWidget` |
| Variables | `camelCase` | `_disposed`, `_cacheTTL` |
| Constants | `camelCase` or `PascalCase` | `routeName`, `routePath` |
| Private members | `_camelCase` | `_service`, `_firestore` |
| Test files | `*_test.dart` (Flutter), `*.test.js` (JS) | `friend_service_test.dart` |

---

## Provider Pattern

### Structure Template
```dart
class FeatureProvider extends ChangeNotifier {
  FeatureProvider({FeatureService? service})
      : _service = service ?? FeatureService();

  final FeatureService _service;
  bool _disposed = false;
  Timer? _notifyDebounce;
  final Duration _cacheTTL = const Duration(minutes: 5);
  final Map<String, DateTime> _cacheTimestamps = {};

  void _scheduleNotify() {
    if (_disposed) return;
    _notifyDebounce?.cancel();
    _notifyDebounce = Timer(const Duration(milliseconds: 50), () {
      if (_disposed) return;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _notifyDebounce?.cancel();
    // Cancel all StreamSubscriptions
    // Close all BehaviorSubjects
    super.dispose();
  }
}
```

### Key Patterns
- **Constructor DI**: Accept service with default — `{GameService? service} : _service = service ?? GameService()`
- **Disposed guard**: Check `_disposed` before every `notifyListeners()`
- **Debounced notify**: 50ms timer via `_scheduleNotify()` — never call `notifyListeners()` directly
- **Cache TTL**: 5-minute `Map<String, DateTime>` timestamps
- **StreamRequestManager**: For reactive Firestore streams with `BehaviorSubject` caching
- **No-op guards**: `if (_value == newValue) return;` before state changes
- **Access**: `context.featureProvider` (read) / `context.watchFeatureProvider` (watch) via `provider_extensions.dart`

### Mutation Pattern
```dart
Future<void> joinGame(String gameId) async {
  try {
    await _service.joinGame(gameId);
    _invalidateQueryCache();
    _scheduleNotify();
  } catch (e) {
    AppLog.d('❌ GameProvider.joinGame error: $e');
    rethrow;
  }
}
```

---

## Service Pattern

### Structure Template
```dart
class FeatureService {
  FeatureService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
}
```

### Key Patterns
- **Instance classes** — never static-only
- **Firestore DI**: Constructor accepts optional `FirebaseFirestore` for testing
- **Error handling**: Catch `FirebaseException` specifically, log with code, rethrow
- **Firestore limits**: whereIn max 10 (chunk), batch max 500
- **Stream composition**: `rxdart` (`switchMap`, `combineLatestList`)
- **Transactions**: For concurrent-safe operations (reactions, chat creation, game join)

### Error Pattern
```dart
on FirebaseException catch (e) {
  AppLog.d('❌ GameService.queryAvailableGames error: ${e.code} - ${e.message}');
  rethrow;
}
```

### Non-Critical Operations
```dart
// Fire-and-forget — don't fail parent operation
try {
  await _syncChatMembership(chatId);
} catch (e) {
  AppLog.d('📖 Non-critical sync failed: $e');
}
```

---

## Widget Structure

### Feature Folder Layout
```
lib/feature_name/
├── feature_widget.dart        # Main screen (max 300 lines)
├── controllers/               # Logic extraction (optional)
├── components/                # Sub-widgets
└── models/                    # Form state models (optional)
```

### Screen Widget Template
```dart
class FeatureWidget extends StatefulWidget {
  static String routeName = 'Feature';
  static String routePath = '/feature';

  @override
  State<FeatureWidget> createState() => _FeatureWidgetState();
}
```

### Critical Rules
- **Max 300 lines** per widget file — decompose into `components/`
- **Mounted check after await**: `if (!mounted) return;`
- **Cancel subscriptions**: Every `StreamSubscription` cancelled in `dispose()`
- **No empty setState**: `setState(() {})` is forbidden — use targeted Provider updates
- **No Firebase calls**: Widgets only access providers, never Firestore/Auth directly

---

## Logging

### AppLog.d() — Single Logging Method
```dart
AppLog.d('✅ GameProvider: Successfully joined game $gameId');
AppLog.d('❌ ChatService.sendMessage error: ${e.code} - ${e.message}');
AppLog.d('📖 ProfileService: Fetching batch of ${ids.length} profiles');
```

### Emoji Prefixes
| Emoji | Meaning |
|-------|---------|
| ✅ | Success/completion |
| ❌ | Error |
| 📖 | Info |
| 📱 | Chat operations |
| 🔵 | Stream events |
| 💬 | Chat UI |
| 🔥 | Cache warming |
| 🆕 | New fetches |

**Never use** `print()` or `debugPrint()`.

---

## Error Handling

### Exception Hierarchy (`lib/core/exceptions/app_exceptions.dart`)
```
AppException (message, code?, cause?)
├─ GameOperationException
├─ FriendOperationException
├─ ChatOperationException
├─ PermissionException
├─ NetworkException
├─ JoinRequestException
└─ BlockOperationException
```

### By Layer
- **Services**: `on FirebaseException catch (e)` → log → rethrow
- **Providers**: catch → log → rethrow
- **UI**: catch → display via `AppSnackbar`
- **Non-critical**: generic `catch` → log silently

---

## Design Token Usage

### Quick Reference
```dart
// Colors
AppColors.green          // CTAs, interactive
AppColors.navy           // Structural surfaces
AppColors.gold           // Accent only (earned, not sprinkled)
AppColors.textPrimary    // Primary text
AppColors.textSecondary  // Secondary text
AppColors.textMuted      // Muted text

// Typography
AppTypography.headlineMediumSans  // Screen titles
AppTypography.titleLarge          // Sections
AppTypography.bodyMedium          // Body text
AppTypography.labelLarge          // Buttons
AppTypography.labelSmall          // Captions
AppTypography.monoDisplay         // Scores/data

// Spacing (8-point grid)
AppSpacing.screenPadding  // Screen edges
AppSpacing.cardPadding    // Card internal
AppSpacing.md             // 16px general
AppSpacing.sm             // 12px tight

// Radius
BorderRadius.circular(AppBorderRadius.card)    // 12px
BorderRadius.circular(AppBorderRadius.button)  // 8px
BorderRadius.circular(AppBorderRadius.modal)   // 16px

// Icons
AppIcon(icon: AppPhosphorIcons.games, size: AppIconSize.md, color: AppColors.textSecondary)
AppNavIcon(icon: AppPhosphorIcons.games, iconFill: AppPhosphorIcons.gamesFill, isActive: true)

// Elevation
AppElevation.card
AppElevation.modal
```

### Rules
- **Never hardcode** colors, font sizes, spacing, border radii, or icon sizes
- **Never use** `Colors.*`, `Color(0x...)`, or raw `Icon()` with hardcoded sizes
- **Use** `AppIcon` with `AppPhosphorIcons` + `AppIconSize` tokens
- **CI enforces** via `tool/check_hardcoded_colors.sh`

---

## Microcopy & Voice

### Tone: Quiet Confidence
- Clear, composed, trustworthy
- Semi-formal, no slang, no corporate buzzwords
- No emoji in system messages/errors/trust flows
- No exclamation marks in system flows
- Sentence case, max 4-word button labels

### Examples
- "You're confirmed for this round." — not "Awesome! You're in!"
- "We couldn't load this round." — not "Uh oh! Something went wrong."
- Use constants from `lib/core/content/app_copy.dart`

---

## Accessibility

- **Vibe sliders**: `semanticFormatterCallback` for descriptive labels
- **Comparison visuals**: `Semantics(excludeSemantics: true, label: '...')`
- **Toggles**: `Semantics(button: true, label: '...')`
- **Dealbreaker switches**: `Semantics(toggled: value, label: '...')`
