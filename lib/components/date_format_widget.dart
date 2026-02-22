import '/utils/app_util.dart';
import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';

class DateFormatWidget extends StatefulWidget {
  const DateFormatWidget({
    super.key,
    this.date,
  });

  final DateTime? date;

  @override
  State<DateFormatWidget> createState() => _DateFormatWidgetState();
}

class _DateFormatWidgetState extends State<DateFormatWidget> {
  @override
  void initState() {
    super.initState();
    // ✅ PERFORMANCE: Removed empty post-frame setState (no-op rebuild)
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          valueOrDefault<String>(
            dateTimeFormat("EEEE", widget.date),
            'Friday',
          ),
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.pure,
          ),
        ),
        Text(
          ',',
          style: AppTypography.headlineMediumSans.copyWith(
            color: Colors.white,
            letterSpacing: 0.0,
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(4.0, 0.0, 0.0, 0.0),
          child: Text(
            valueOrDefault<String>(
              dateTimeFormat("MMMM", widget.date),
              'July',
            ),
            style: AppTypography.bodyLarge.copyWith(
              color: Colors.white,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(4.0, 0.0, 0.0, 0.0),
          child: Text(
            valueOrDefault<String>(
              dateTimeFormat("d", widget.date),
              '1',
            ),
            style: AppTypography.bodyLarge.copyWith(
              color: Colors.white,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 0.0, 0.0),
          child: Text(
            valueOrDefault<String>(
              dateTimeFormat("jm", widget.date),
              '00:00',
            ),
            style: AppTypography.bodyLarge.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
