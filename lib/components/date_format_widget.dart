import '/utils/app_util.dart';
import 'package:flutter/material.dart';

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
          style: AppTypography.bodyLarge.override(
                font: TextStyle(fontFamily: 'Manrope',
                  fontWeight: AppTypography.bodyLarge.fontWeight,
                  fontStyle: AppTypography.bodyLarge.fontStyle,
                ),
                color: AppColors.navyDarkBtnText,
                letterSpacing: 0.0,
                fontWeight: AppTypography.bodyLarge.fontWeight,
                fontStyle: AppTypography.bodyLarge.fontStyle,
              ),
        ),
        Text(
          ',',
          style: AppTypography.headlineMedium.override(
                font: TextStyle(fontFamily: 'Manrope',
                  fontWeight:
                      AppTypography.headlineMedium.fontWeight,
                  fontStyle:
                      AppTypography.headlineMedium.fontStyle,
                ),
                color: Colors.white,
                letterSpacing: 0.0,
                fontWeight:
                    AppTypography.headlineMedium.fontWeight,
                fontStyle:
                    AppTypography.headlineMedium.fontStyle,
              ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(4.0, 0.0, 0.0, 0.0),
          child: Text(
            valueOrDefault<String>(
              dateTimeFormat("MMMM", widget.date),
              'July',
            ),
            style: AppTypography.bodyLarge.override(
                  font: TextStyle(fontFamily: 'Manrope',
                    fontWeight:
                        AppTypography.bodyLarge.fontWeight,
                    fontStyle: AppTypography.bodyLarge.fontStyle,
                  ),
                  color: Colors.white,
                  letterSpacing: 0.0,
                  fontWeight: AppTypography.bodyLarge.fontWeight,
                  fontStyle: AppTypography.bodyLarge.fontStyle,
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
            style: AppTypography.bodyLarge.override(
                  font: TextStyle(fontFamily: 'Manrope',
                    fontWeight:
                        AppTypography.bodyLarge.fontWeight,
                    fontStyle: AppTypography.bodyLarge.fontStyle,
                  ),
                  color: Colors.white,
                  letterSpacing: 0.0,
                  fontWeight: AppTypography.bodyLarge.fontWeight,
                  fontStyle: AppTypography.bodyLarge.fontStyle,
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
            style: AppTypography.bodyLarge.override(
                  font: TextStyle(fontFamily: 'Manrope',
                    fontWeight:
                        AppTypography.bodyLarge.fontWeight,
                    fontStyle: AppTypography.bodyLarge.fontStyle,
                  ),
                  color: Colors.white,
                  letterSpacing: 0.0,
                  fontWeight: AppTypography.bodyLarge.fontWeight,
                  fontStyle: AppTypography.bodyLarge.fontStyle,
                ),
          ),
        ),
      ],
    );
  }
}
