// Automatic FlutterFlow imports
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

class DynamicTextSize extends StatefulWidget {
  const DynamicTextSize({
    super.key,
    this.width,
    this.height,
    required this.text,
    this.textStyle,
  });

  final double? width;
  final double? height;
  final String text;
  final TextStyle? textStyle;

  @override
  State<DynamicTextSize> createState() => _DynamicTextSizeState();
}

class _DynamicTextSizeState extends State<DynamicTextSize> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedTextStyle = widget.textStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'Outfit',
          fontSize: 14,
          color: theme.colorScheme.onPrimary,
        );
    return Container(
      padding: EdgeInsets.all(4),
      alignment: AlignmentDirectional(0, 0),
      child: widget.text.split(' ').first.length > 9
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.text.split(' ').toList().join('\n'),
                style: resolvedTextStyle,
                textAlign: TextAlign.center,
              ),
            )
          : Text(
              widget.text,
              style: resolvedTextStyle,
              textAlign: TextAlign.center,
            ),
    );
  }
}
