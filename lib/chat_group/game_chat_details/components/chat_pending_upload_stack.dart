import 'package:flutter/material.dart';

import 'chat_pending_upload_bubble.dart';

class ChatPendingUploadStack extends StatelessWidget {
  const ChatPendingUploadStack({
    super.key,
    required this.pendingUploads,
  });

  final List<PendingUploadItem> pendingUploads;

  @override
  Widget build(BuildContext context) {
    if (pendingUploads.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: pendingUploads
          .map((upload) => ChatPendingUploadBubble(upload: upload))
          .toList(),
    );
  }
}
