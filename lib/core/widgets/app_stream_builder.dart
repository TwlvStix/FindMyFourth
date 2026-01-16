import 'package:flutter/material.dart';
import 'app_loading_state.dart';
import 'app_empty_state.dart';

class AppStreamBuilder<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final String? loadingMessage;
  final IconData? emptyIcon;
  final String? emptyTitle;
  final String? emptyMessage;

  const AppStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.loadingMessage,
    this.emptyIcon,
    this.emptyTitle,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AppEmptyState(
            icon: Icons.error_outline,
            title: 'Something went wrong',
            message: snapshot.error.toString(),
          );
        }

        if (!snapshot.hasData) {
          return AppLoadingState(
            variant: loadingMessage != null
                ? AppLoadingVariant.message
                : AppLoadingVariant.spinner,
            message: loadingMessage,
          );
        }

        final data = snapshot.data as T;

        // Check if data is empty list
        if (data is List && data.isEmpty) {
          return AppEmptyState(
            icon: emptyIcon ?? Icons.inbox_outlined,
            title: emptyTitle ?? 'No items',
            message: emptyMessage,
          );
        }

        return builder(context, data);
      },
    );
  }
}
