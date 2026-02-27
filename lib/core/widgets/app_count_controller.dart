import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/border_radius.dart';

class AppCountController extends StatefulWidget {
  const AppCountController({
    Key? key,
    required this.decrementIconBuilder,
    required this.incrementIconBuilder,
    required this.countBuilder,
    required this.count,
    required this.updateCount,
    this.stepSize = 1,
    this.minimum,
    this.maximum,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 25.0),
    this.editable = false,
    this.formatValue,
    this.parseValue,
  }) : super(key: key);

  final Widget Function(bool enabled) decrementIconBuilder;
  final Widget Function(bool enabled) incrementIconBuilder;
  final Widget Function(int count) countBuilder;
  final int count;
  final Function(int) updateCount;
  final int stepSize;
  final int? minimum;
  final int? maximum;
  final EdgeInsetsGeometry contentPadding;

  /// When true, tapping on the count display enters inline edit mode.
  final bool editable;

  /// Formats the count value for display in the text field.
  /// If null, uses count.toString().
  final String Function(int)? formatValue;

  /// Parses the text input back to an integer.
  /// Return null for invalid input (will revert to previous value).
  /// If null, uses int.tryParse.
  final int? Function(String)? parseValue;

  @override
  _AppCountControllerState createState() => _AppCountControllerState();
}

class _AppCountControllerState extends State<AppCountController> {
  bool _isEditing = false;
  late TextEditingController _textController;
  late FocusNode _focusNode;

  int get count => widget.count;
  int? get minimum => widget.minimum;
  int? get maximum => widget.maximum;
  int get stepSize => widget.stepSize;

  bool get canDecrement => minimum == null || count - stepSize >= minimum!;
  bool get canIncrement => maximum == null || count + stepSize <= maximum!;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _submitValue();
    }
  }

  void _startEditing() {
    if (!widget.editable) return;

    final displayValue = widget.formatValue?.call(count) ?? count.toString();
    _textController.text = displayValue;
    setState(() => _isEditing = true);

    // Schedule focus and selection after the text field is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _textController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _textController.text.length,
      );
    });
  }

  void _submitValue() {
    final text = _textController.text.trim();
    int? newValue;

    if (text.isNotEmpty) {
      newValue = widget.parseValue?.call(text) ?? int.tryParse(text);
    }

    setState(() => _isEditing = false);

    if (newValue != null) {
      // Clamp to min/max range
      if (minimum != null && newValue < minimum!) {
        newValue = minimum!;
      }
      if (maximum != null && newValue > maximum!) {
        newValue = maximum!;
      }
      widget.updateCount(newValue);
    }
    // If newValue is null (invalid input), keep the previous value
  }

  void _decrementCounter() {
    if (canDecrement) {
      setState(() => widget.updateCount(count - stepSize));
    }
  }

  void _incrementCounter() {
    if (canIncrement) {
      setState(() => widget.updateCount(count + stepSize));
    }
  }

  Widget _buildCountDisplay() {
    if (_isEditing && widget.editable) {
      return Container(
        constraints: const BoxConstraints(minWidth: 56),
        child: IntrinsicWidth(
          child: TextField(
            controller: _textController,
            focusNode: _focusNode,
            cursorColor: AppColors.textPrimary,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            textAlign: TextAlign.center,
            style: AppTypography.monoLarge.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.85),
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                borderSide: BorderSide(color: AppColors.inputBorderFocused),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                borderSide: BorderSide(color: AppColors.inputBorderFocused),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                borderSide:
                    BorderSide(color: AppColors.inputBorderFocused, width: 2),
              ),
              filled: true,
              fillColor: AppColors.inputBackground,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^[+\-]?\d*$')),
            ],
            onSubmitted: (_) => _submitValue(),
          ),
        ),
      );
    }

    final countWidget = widget.countBuilder(count);

    if (widget.editable) {
      return GestureDetector(
        onTap: _startEditing,
        child: countWidget,
      );
    }

    return countWidget;
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: widget.contentPadding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: _decrementCounter,
              child: widget.decrementIconBuilder(canDecrement),
            ),
            _buildCountDisplay(),
            InkWell(
              onTap: _incrementCounter,
              child: widget.incrementIconBuilder(canIncrement),
            ),
          ],
        ),
      );
}
