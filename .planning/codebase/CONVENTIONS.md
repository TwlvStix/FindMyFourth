# Coding Conventions

**Analysis Date:** 2026-01-14

## Naming Patterns

**Files:**
- Widgets: `{feature_name}_widget.dart` (e.g., `create_game_widget.dart`, `chat_widget.dart`)
- Services: `snake_case_service.dart` (e.g., `chat_service.dart`, `vibe_matcher.dart`)
- Models: `snake_case.dart` (e.g., `vibe_profile.dart`, `chat.dart`)
- Tests: `{name}_test.dart` (co-located in `test/` directory)

**Functions:**
- camelCase for all functions (e.g., `getChatListStream()`, `createOrGetDirectChat()`)
- Async functions: no special prefix (e.g., `Future<void> sendMessage()`)
- Private functions: `_prefixedWithUnderscore()` (e.g., `_buildProfile()`, `_clamp()`)

**Variables:**
- camelCase for variables and parameters
- Private members: `_prefixedWithUnderscore` (e.g., `_firestore`, `_userCache`)
- Constructor parameter names match field names with `required` keyword

**Types:**
- PascalCase for classes (e.g., `ChatService`, `VibeProfile`, `AppButton`)
- PascalCase for interfaces/abstract classes (no I prefix)
- Enum values: lowercase within enum (e.g., `VibeCategory.drinking`, `VibeCategory.music`)
- Generic type parameters: single uppercase letter (e.g., `StreamRequestManager<T>`)

## Code Style

**Formatting:**
- Indentation: 2 spaces (Dart standard)
- Quotes: Single quotes for strings (Dart convention)
- Semicolons: Required
- Line length: No strict limit, but readable
- Nullable types: Explicitly marked with `?` (e.g., `String?`, `int?`)

**Linting:**
- flutter_lints 4.0.0 - Standard Flutter linting rules
- lints 4.0.0 - Dart linting
- Configuration: `analysis_options.yaml` (minimal, excludes `lib/custom_code/**`)
- No custom ESLint or Prettier config

## Import Organization

**Order:**
1. Dart SDK imports (e.g., `import 'dart:async';`)
2. Flutter framework imports (e.g., `import 'package:flutter/material.dart';`)
3. External package imports (e.g., `import 'package:provider/provider.dart';`)
4. Absolute project imports with leading `/` (e.g., `import '/models/chat.dart';`)
5. Relative imports (rare, mostly avoided)

**Grouping:**
- Blank lines between groups
- No alphabetical sorting enforced
- Related imports grouped together

**Path Patterns:**
- Absolute imports use leading `/` within project (e.g., `import '/core/app_theme.dart';`)
- Package imports use `package:` prefix

## Error Handling

**Patterns:**
- Try-catch with rethrow for added context
- FirebaseException and FirebaseAuthException for Firebase errors
- Custom error messages in catch blocks
- Stack trace logging with `debugPrint()` in development

**Error Types:**
- Throw on invalid state or failed operations
- FirebaseException for Firestore/Auth errors
- Generic Exception for business logic errors
- Return null for optional data, throw for required data

**Logging:**
- Use `debugPrint()` for development logging (automatically stripped in release)
- Emoji prefixes for log categories (💬 chat, 📨 messages, 🔧 debug, ✅ success, ❌ error)
- Avoid `print()` statements (use `debugPrint()` instead)

## Logging

**Framework:**
- debugPrint() - Flutter's debug-only logging
- print() - Avoided in favor of debugPrint()

**Patterns:**
- Emoji prefixes for visual scanning: `debugPrint('💬 ChatService: getChatListStream called');`
- Include method name and context in log messages
- Log entry/exit of critical methods
- Log state transitions

**When:**
- State changes in providers
- Service method entry/exit
- Firebase operations (read/write)
- Error conditions

**Where:**
- Services: Extensive logging in `chat_service.dart`, `vibe_repository.dart`
- Providers: Debug logs in `user_provider.dart`
- Navigation: Auth state transitions in `app_router.dart`

## Comments

**When to Comment:**
- Explain why, not what (code is self-documenting for what)
- Document business logic (e.g., vibe matching algorithm)
- Explain non-obvious patterns or workarounds
- TODOs for incomplete features (e.g., message reply feature)

**JSDoc/TSDoc:**
- Not consistently used in examined files
- No formal doc comments (`///`) found
- Documentation through code structure and type hints

**TODO Comments:**
- Format: `// TODO: description` or `// TODO(username): description`
- Example: `// TODO: store replyTo message ID in message document`
- Location: Inline where feature is incomplete

## Function Design

**Size:**
- No strict limit, but large widgets (1700+ lines) are a concern
- Complex logic extracted to helper methods
- Widgets often contain build() methods with nested builders

**Parameters:**
- Use `required` keyword for mandatory parameters
- Named parameters for clarity (Flutter convention)
- Destructuring in callbacks (e.g., `(context, state) => ...`)

**Return Values:**
- Explicit return types (e.g., `Future<void>`, `Stream<List<Chat>>`)
- Nullable return types marked with `?`
- Factory constructors for model conversion (e.g., `Chat.fromDoc()`)

## Module Design

**Exports:**
- Named exports preferred (Dart default)
- No default exports (Dart doesn't support)
- Barrel files: `index.dart` in `lib/custom_code/` for re-exports

**Patterns:**
- Services as singletons or stateless classes
- Providers extend ChangeNotifier
- Models are immutable data classes
- Records (backend schema) separate from Models (domain)

**Dependency Injection:**
- Providers injected via MultiProvider in `main.dart`
- Services passed to providers via constructor
- Firebase instances accessed via singletons

## State Management

**Patterns:**
- Provider + ChangeNotifier for global state
- StatefulWidget for local state
- StreamBuilder for reactive Firebase data
- StreamRequestManager/FutureRequestManager for caching

**Conventions:**
- Call `notifyListeners()` after state changes
- Use `context.watch<T>()` for reactive dependencies
- Use `context.read<T>()` for one-time access
- Private state variables prefixed with `_`

## Async Patterns

**Preferred:**
- `async`/`await` syntax over `.then()`
- `Stream<T>` for real-time data
- `Future<T>` for one-time async operations

**Examples:**
- Firestore queries return `Stream<QuerySnapshot>`
- Service methods return `Future<void>` or `Future<T>`
- StreamBuilder widgets subscribe to streams

---

*Convention analysis: 2026-01-14*
*Update when patterns change*
