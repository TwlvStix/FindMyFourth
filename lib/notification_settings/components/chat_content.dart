import 'package:flutter/material.dart';
import '/providers/provider_extensions.dart';
import '/notification_settings/components/expand_section_label.dart';
import '/notification_settings/components/delivery_frequency_selector.dart';

/// Expanded content for the Chat Messages notification category card.
///
/// Shows a simple delivery frequency selector.
class ChatContent extends StatelessWidget {
  const ChatContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watchNotificationProvider;
    final prefs = provider.preferences;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const ExpandSectionLabel(text: 'DELIVERY', showDivider: false),
        DeliveryFrequencySelector(
          selected: prefs.chatAlerts.deliveryFrequency,
          onChanged: (freq) {
            context.notificationProvider.updateChatAlerts(delivery: freq);
          },
        ),
      ],
    );
  }
}
