import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'app_router.dart';

/// Standard transition configurations for consistent navigation throughout the app.
///
/// These standards eliminate the 8 identified navigation inconsistencies by
/// providing clear, semantic transition types with consistent durations.
///
/// ## Design Philosophy
///
/// Transitions serve two purposes:
/// 1. **Visual Feedback**: User understands what happened (modal opened, detail pushed, etc.)
/// 2. **Spatial Context**: Direction indicates relationship (bottom-up = new layer, fade = lateral move)
///
/// ## Usage Guidelines
///
/// Choose transitions based on the **semantic purpose** of the navigation:
///
/// - **Modal-like screens** (create, edit, add): Use `modalTransition`
///   - Creates new content layer on top of current context
///   - Examples: create_game, edit_profile, add_players
///
/// - **Detail views** (expanding into details): Use `detailTransition`
///   - Drilling deeper into existing content
///   - Examples: game_details, chat_details, user_profile
///
/// - **Success/dismissal screens**: Use `dismissalTransition`
///   - Temporary overlays that auto-dismiss or confirm actions
///   - Examples: success_page, success_leave
///
/// - **Tab-level navigation**: Use `tabTransition`
///   - Lateral movement within bottom navigation tabs
///   - Examples: switching between profile tabs
///
/// - **Deep navigation** (instant): Use `noTransition`
///   - Deep links or programmatic navigation where animation would confuse
///   - Examples: notification deep links, auth redirects
///
/// ## Anti-Patterns to Avoid
///
/// ❌ `context.pushNamed(route)` without transition - Uses platform default (inconsistent)
/// ❌ Mixing durations (200ms, 250ms, 300ms) - Creates inconsistent feel
/// ❌ Using `pushNamed` to return from modals - Should use `pop()` or `goNamed()`
/// ❌ `router.go()` instead of `context.goNamed()` - Bypasses transition system
///
class TransitionStandards {
  /// Modal-like screens transition (create, edit, add players).
  ///
  /// Bottom-to-top slide creates sense of new content layer appearing over current context.
  /// Use for any screen where user is creating or editing content.
  ///
  /// **Duration**: 220ms (slightly faster than Material's 300ms for modern feel)
  ///
  /// **Examples**:
  /// ```dart
  /// // Creating new content
  /// context.pushNamed('create_game', extra: {'kTransitionInfoKey': TransitionStandards.modalTransition});
  ///
  /// // Editing existing content
  /// context.pushNamed('edit_profile', extra: {'kTransitionInfoKey': TransitionStandards.modalTransition});
  ///
  /// // Adding items to existing content
  /// context.pushNamed('add_players', extra: {'kTransitionInfoKey': TransitionStandards.modalTransition});
  /// ```
  static const modalTransition = TransitionInfo(
    hasTransition: true,
    transitionType: PageTransitionType.bottomToTop,
    duration: Duration(milliseconds: 220),
  );

  /// Detail view transition (game details, chat details, profile views).
  ///
  /// Bottom-to-top slide indicates drilling deeper into existing content.
  /// Use when expanding from a list item into its full details.
  ///
  /// **Duration**: 220ms (consistent with modal for unified feel)
  ///
  /// **Examples**:
  /// ```dart
  /// // From games list to game details
  /// context.pushNamed('game_details', extra: {'kTransitionInfoKey': TransitionStandards.detailTransition});
  ///
  /// // From chat list to chat conversation
  /// context.pushNamed('chat', extra: {'kTransitionInfoKey': TransitionStandards.detailTransition});
  ///
  /// // From golfers list to user profile
  /// context.pushNamed('profile_user', extra: {'kTransitionInfoKey': TransitionStandards.detailTransition});
  /// ```
  static const detailTransition = TransitionInfo(
    hasTransition: true,
    transitionType: PageTransitionType.bottomToTop,
    duration: Duration(milliseconds: 220),
  );

  /// Success/dismissal screen transition.
  ///
  /// Top-to-bottom slide creates sense of temporary overlay that will dismiss.
  /// Use for confirmation screens, success messages, or temporary feedback.
  ///
  /// **Duration**: 220ms (same as modal/detail for consistency)
  ///
  /// **Examples**:
  /// ```dart
  /// // Success confirmation after action
  /// context.pushNamed('success_page', extra: {'kTransitionInfoKey': TransitionStandards.dismissalTransition});
  ///
  /// // Leave game confirmation
  /// context.pushNamed('success_leave', extra: {'kTransitionInfoKey': TransitionStandards.dismissalTransition});
  /// ```
  static const dismissalTransition = TransitionInfo(
    hasTransition: true,
    transitionType: PageTransitionType.topToBottom,
    duration: Duration(milliseconds: 220),
  );

  /// Tab-level navigation transition within bottom nav.
  ///
  /// Fade transition creates sense of lateral movement at same depth level.
  /// Use for switching between tabs or sibling screens at same hierarchy level.
  ///
  /// **Duration**: 200ms (slightly faster for immediate feel of tab switching)
  ///
  /// **Examples**:
  /// ```dart
  /// // Switching between profile tabs
  /// context.goNamed('profile_tab_1', extra: {'kTransitionInfoKey': TransitionStandards.tabTransition});
  ///
  /// // Moving between sibling sections
  /// context.goNamed('games_joined', extra: {'kTransitionInfoKey': TransitionStandards.tabTransition});
  /// ```
  static const tabTransition = TransitionInfo(
    hasTransition: true,
    transitionType: PageTransitionType.fade,
    duration: Duration(milliseconds: 200),
  );

  /// No transition (instant navigation).
  ///
  /// Instant navigation for programmatic flows where animation would be confusing.
  /// Use sparingly - only for deep links, auth redirects, or background navigation.
  ///
  /// **Examples**:
  /// ```dart
  /// // Deep link from notification
  /// context.goNamed('game_details', extra: {'kTransitionInfoKey': TransitionStandards.noTransition});
  ///
  /// // Auth redirect after login
  /// context.goNamed('games_list', extra: {'kTransitionInfoKey': TransitionStandards.noTransition});
  /// ```
  static const noTransition = TransitionInfo(hasTransition: false);
}

/// Convenience extension methods for navigation with standard transitions.
///
/// These helpers reduce boilerplate and make it easier to apply correct transitions.
///
/// ## Usage Examples
///
/// ```dart
/// // Instead of:
/// context.pushNamed('create_game', extra: {'kTransitionInfoKey': TransitionStandards.modalTransition});
///
/// // Use:
/// context.pushModal('create_game');
///
/// // Instead of:
/// context.pushNamed('game_details', extra: {'kTransitionInfoKey': TransitionStandards.detailTransition});
///
/// // Use:
/// context.pushDetail('game_details');
/// ```
///
extension TransitionNavigation on BuildContext {
  /// Push a modal-like screen (create, edit, add).
  ///
  /// Uses bottom-to-top slide transition (220ms).
  void pushModal(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) {
    final extraWithTransition = _mergeExtra(extra, TransitionStandards.modalTransition);
    pushNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extraWithTransition,
    );
  }

  /// Push a detail view screen (game details, chat details, profile).
  ///
  /// Uses bottom-to-top slide transition (220ms).
  void pushDetail(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) {
    final extraWithTransition = _mergeExtra(extra, TransitionStandards.detailTransition);
    pushNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extraWithTransition,
    );
  }

  /// Navigate with a custom transition.
  ///
  /// Use when you need to specify a non-standard transition or override defaults.
  void goWithTransition(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
    required TransitionInfo transition,
  }) {
    final extraWithTransition = _mergeExtra(extra, transition);
    goNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extraWithTransition,
    );
  }

  /// Merge extra data with transition info.
  ///
  /// If extra is already a Map, adds kTransitionInfoKey to it.
  /// Otherwise, creates new Map with transition and preserves extra as-is.
  Map<String, dynamic> _mergeExtra(Object? extra, TransitionInfo transition) {
    if (extra is Map<String, dynamic>) {
      return {
        ...extra,
        kTransitionInfoKey: transition,
      };
    } else if (extra != null) {
      // Extra is a custom object (like game reference), preserve it
      return {
        'data': extra,
        kTransitionInfoKey: transition,
      };
    } else {
      return {kTransitionInfoKey: transition};
    }
  }
}
