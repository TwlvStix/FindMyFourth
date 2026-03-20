import 'package:flutter/material.dart';

/// Reusable Semantics wrapper for tappable elements.
///
/// Wraps any child widget with [Semantics] to provide screen reader labels
/// for interactive elements that don't natively expose accessibility info.
class SemanticTapWrapper extends StatelessWidget {
  const SemanticTapWrapper({
    super.key,
    required this.label,
    required this.child,
    this.button = true,
    this.toggled,
    this.header = false,
  });

  /// Screen reader label describing the element's action or content.
  final String label;

  /// The interactive child widget to wrap.
  final Widget child;

  /// Whether this element behaves as a button (default: true).
  final bool button;

  /// If non-null, announces the toggle state to screen readers.
  final bool? toggled;

  /// Whether this element is a section header.
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: button,
      label: label,
      toggled: toggled,
      header: header,
      child: child,
    );
  }
}
