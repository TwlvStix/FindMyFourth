import 'package:flutter/material.dart';

/// Expanded content for the Chat Messages notification category card.
///
/// Currently empty - delivery frequency selector hidden until backend digest
/// logic is complete.
/// To re-enable: add DeliveryFrequencySelector with prefs.chatAlerts.deliveryFrequency
class ChatContent extends StatelessWidget {
  const ChatContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Delivery frequency selector hidden until backend digest logic is complete.
    // To re-enable: add ExpandSectionLabel + DeliveryFrequencySelector here.
    return const SizedBox.shrink();
  }
}
