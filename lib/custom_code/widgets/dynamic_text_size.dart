// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/core/app_theme.dart';
import '/core/app_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/core/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:auto_size_text/auto_size_text.dart';

class DynamicTextSize extends StatefulWidget {
  const DynamicTextSize({
    super.key,
    this.width,
    this.height,
    required this.text,
  });

  final double? width;
  final double? height;
  final String text;

  @override
  State<DynamicTextSize> createState() => _DynamicTextSizeState();
}

class _DynamicTextSizeState extends State<DynamicTextSize> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4),
      alignment: AlignmentDirectional(0, 0),
      child: widget.text.split(' ').first.length > 9
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.text.split(' ').toList().join('\n'),
                style: AppTheme.of(context).bodyMedium.override(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: AppTheme.of(context).primaryBtnText,
                      letterSpacing: 0,
                    ),
                textAlign: TextAlign.center,
              ),
            )
          : Text(
              widget.text,
              style: AppTheme.of(context).bodyMedium.override(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    color: AppTheme.of(context).primaryBtnText,
                    letterSpacing: 0,
                  ),
              textAlign: TextAlign.center,
            ),
    );
  }
}
