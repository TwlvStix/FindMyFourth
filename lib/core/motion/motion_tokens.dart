import 'package:flutter/material.dart';

/// Premium Motion System - Single Source of Truth
///
/// This module defines all animation durations, curves, scales, and stagger rules
/// for the entire application. All animations MUST reference these tokens to ensure
/// consistency and accessibility support.
///
/// Design Spec: Premium Motion System v1.0
/// - Enter: Curves.easeOutCubic (content appearing)
/// - Exit: Curves.easeInCubic (content disappearing)
/// - Durations: Split enter/exit for polish
/// - Reduced Motion: 35% faster, no scale, no stagger
class MotionTokens {
  MotionTokens._(); // Prevent instantiation

  // ============================================================================
  // DURATIONS - Reference these instead of hardcoded milliseconds
  // ============================================================================

  /// Route navigation enter duration (200ms)
  /// Used for: StandardPage, FullscreenModal
  static const Duration routeEnter = Duration(milliseconds: 200);

  /// Route navigation exit duration (170ms)
  /// Used for: All route exits (15% faster than enter for snappiness)
  static const Duration routeExit = Duration(milliseconds: 170);

  /// Bottom sheet enter duration (260ms)
  /// Slightly longer to feel substantial sliding up
  static const Duration bottomSheetEnter = Duration(milliseconds: 260);

  /// Bottom sheet exit duration (220ms)
  static const Duration bottomSheetExit = Duration(milliseconds: 220);

  /// Dialog enter duration (200ms)
  /// Matches routes for consistency
  static const Duration dialogEnter = Duration(milliseconds: 200);

  /// Dialog exit duration (170ms)
  static const Duration dialogExit = Duration(milliseconds: 170);

  /// Backdrop fade duration (160ms)
  /// Slightly faster than foreground for depth perception
  static const Duration backdropFade = Duration(milliseconds: 160);

  /// In-page content reveal duration (160ms)
  /// Used for: Staggered fades, content appearing on scroll
  static const Duration contentReveal = Duration(milliseconds: 160);

  /// Micro-interaction duration (100ms)
  /// Used for: Button presses, toggles, checkbox, hover, focus
  static const Duration microInteraction = Duration(milliseconds: 100);

  // ============================================================================
  // CURVES - Always use semantic enter/exit
  // ============================================================================

  /// Enter curve for content appearing (easeOutCubic)
  /// Starts fast, ends slow - creates smooth arrival
  static const Curve curveEnter = Curves.easeOutCubic;

  /// Exit curve for content disappearing (easeInCubic)
  /// Starts slow, ends fast - creates snappy exit
  static const Curve curveExit = Curves.easeInCubic;

  // ============================================================================
  // SCALE VALUES
  // ============================================================================

  /// Page push scale start value (0.985)
  /// Subtle micro-scale on route push only (not pop)
  static const double pageScaleStart = 0.985;

  /// Page push scale end value (1.0)
  static const double pageScaleEnd = 1.0;

  /// Dialog scale start value (0.97)
  /// Noticeable scale creates sense of depth
  static const double dialogScaleStart = 0.97;

  /// Dialog scale end value (1.0)
  static const double dialogScaleEnd = 1.0;

  /// Standard press scale for interactive elements (0.96)
  static const double pressScale = 0.96;

  /// Subtle press scale for larger card-level elements (0.982)
  static const double pressScaleSubtle = 0.982;

  // ============================================================================
  // STAGGER RULES
  // ============================================================================

  /// Stagger delay between items (24ms)
  /// Used for: Sequential content reveals (e.g., create_profile cards)
  static const Duration staggerDelay = Duration(milliseconds: 24);

  /// Maximum items to stagger (8)
  /// Beyond 8 items, no additional stagger (feels too slow)
  static const int staggerMaxItems = 8;

  // ============================================================================
  // REDUCED MOTION CONFIGURATION
  // ============================================================================

  /// Duration scaling factor for reduced motion (0.65)
  /// Reduces all durations by ~35% when reduced motion is enabled
  static const double reducedMotionDurationScale = 0.65;
}
