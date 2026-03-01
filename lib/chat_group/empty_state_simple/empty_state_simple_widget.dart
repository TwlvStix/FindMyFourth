import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/typography.dart';

class EmptyStateSimpleWidget extends StatefulWidget {
  const EmptyStateSimpleWidget({
    super.key,
    this.icon,
    String? title,
    String? body,
  })  : title = title ?? 'No Comments',
        body = body ?? 'There are no comments associated with this post.';

  final Widget? icon;
  final String title;
  final String body;

  @override
  State<EmptyStateSimpleWidget> createState() => _EmptyStateSimpleWidgetState();
}

class _EmptyStateSimpleWidgetState extends State<EmptyStateSimpleWidget> {
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
    return Align(
      alignment: AlignmentDirectional(0.0, -1.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.icon!,
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0.0),
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTypography.headlineSmallSans.copyWith(
                color: AppColors.pure,
                letterSpacing: 0.0,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 0.0),
            child: Text(
              widget.body,
              textAlign: TextAlign.center,
              style: AppTypography.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}
