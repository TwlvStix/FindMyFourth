import 'package:flutter/material.dart';
import '/core/design_tokens/colors.dart';
import '/core/design_tokens/icon_size.dart';
import '/core/design_tokens/spacing.dart';
import 'package:find_my_fourth/core/utils/error_messages.dart';
import 'package:find_my_fourth/core/exceptions/app_exceptions.dart';

/// Universal StreamBuilder with error states and retry mechanism
class AppStreamBuilder<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final VoidCallback? onRetry;
  final T? initialData;

  const AppStreamBuilder({
    Key? key,
    required this.stream,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.onRetry,
    this.initialData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: initialData,
      builder: (context, snapshot) {
        // Error state
        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error!) ??
              _defaultError(context, snapshot.error!);
        }

        // Data state
        if (snapshot.hasData) {
          return builder(context, snapshot.data!);
        }

        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder?.call(context) ?? _defaultLoading();
        }

        // Empty/no data state
        return _defaultLoading();
      },
    );
  }

  Widget _defaultLoading() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _defaultError(BuildContext context, Object error) {
    String message = ErrorMessages.genericError;

    // Extract user-friendly message from error
    if (error is AppException) {
      message = error.message;
    } else if (error.toString().contains('permission-denied')) {
      message = ErrorMessages.forFirebaseCode('permission-denied');
    } else if (error.toString().contains('unavailable')) {
      message = ErrorMessages.forFirebaseCode('unavailable');
    }

    return Center(
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: AppIconSize.xxl, color: AppColors.error),
            AppSpacing.verticalMdBox,
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            if (onRetry != null) ...[
              AppSpacing.verticalMdBox,
              ElevatedButton(
                onPressed: onRetry,
                child: Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
