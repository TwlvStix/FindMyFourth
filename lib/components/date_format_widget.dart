import '/core/app_theme.dart';
import '/core/app_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
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
          style: AppTheme.of(context).bodyLarge.override(
                font: GoogleFonts.outfit(
                  fontWeight: AppTheme.of(context).bodyLarge.fontWeight,
                  fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
                ),
                color: AppTheme.of(context).primaryBtnText,
                letterSpacing: 0.0,
                fontWeight: AppTheme.of(context).bodyLarge.fontWeight,
                fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
              ),
        ),
        Text(
          ',',
          style: AppTheme.of(context).headlineMedium.override(
                font: GoogleFonts.outfit(
                  fontWeight:
                      AppTheme.of(context).headlineMedium.fontWeight,
                  fontStyle:
                      AppTheme.of(context).headlineMedium.fontStyle,
                ),
                color: Colors.white,
                letterSpacing: 0.0,
                fontWeight:
                    AppTheme.of(context).headlineMedium.fontWeight,
                fontStyle:
                    AppTheme.of(context).headlineMedium.fontStyle,
              ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(4.0, 0.0, 0.0, 0.0),
          child: Text(
            valueOrDefault<String>(
              dateTimeFormat("MMMM", widget.date),
              'July',
            ),
            style: AppTheme.of(context).bodyLarge.override(
                  font: GoogleFonts.outfit(
                    fontWeight:
                        AppTheme.of(context).bodyLarge.fontWeight,
                    fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
                  ),
                  color: Colors.white,
                  letterSpacing: 0.0,
                  fontWeight: AppTheme.of(context).bodyLarge.fontWeight,
                  fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
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
            style: AppTheme.of(context).bodyLarge.override(
                  font: GoogleFonts.outfit(
                    fontWeight:
                        AppTheme.of(context).bodyLarge.fontWeight,
                    fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
                  ),
                  color: Colors.white,
                  letterSpacing: 0.0,
                  fontWeight: AppTheme.of(context).bodyLarge.fontWeight,
                  fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
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
            style: AppTheme.of(context).bodyLarge.override(
                  font: GoogleFonts.outfit(
                    fontWeight:
                        AppTheme.of(context).bodyLarge.fontWeight,
                    fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
                  ),
                  color: Colors.white,
                  letterSpacing: 0.0,
                  fontWeight: AppTheme.of(context).bodyLarge.fontWeight,
                  fontStyle: AppTheme.of(context).bodyLarge.fontStyle,
                ),
          ),
        ),
      ],
    );
  }
}
