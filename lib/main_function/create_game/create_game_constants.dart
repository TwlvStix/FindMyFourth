import 'package:flutter/material.dart';

const List<Map<String, dynamic>> kCreateGamePrimaryFormatOptions = [
  {
    'value': 'Stroke Play',
    'label': 'Stroke Play',
    'icon': Icons.format_list_numbered_rounded,
    'emoji': '📝',
  },
  {
    'value': 'Match Play',
    'label': 'Match Play',
    'icon': Icons.sports_golf_rounded,
    'emoji': '🆚',
  },
  {
    'value': 'Stableford',
    'label': 'Stableford',
    'icon': Icons.star_rounded,
    'emoji': '⭐',
  },
];

const List<Map<String, dynamic>> kCreateGameVibeOptions = [
  {
    'value': 'Competitive',
    'label': 'Competitive',
    'icon': Icons.emoji_events_rounded,
    'emoji': '🏆',
    'subtitle': 'Rules-focused • pace matters',
  },
  {
    'value': 'Casual',
    'label': 'Casual',
    'icon': Icons.sentiment_satisfied_rounded,
    'emoji': '😊',
    'subtitle': 'Relaxed rules • good vibes',
  },
];

const List<Map<String, dynamic>> kCreateGameStakesOptions = [
  {
    'value': 'No Money',
    'label': 'No Money',
    'icon': Icons.handshake_rounded,
    'emoji': '🤝',
  },
  {
    'value': 'Low Stakes',
    'label': 'Low Stakes',
    'icon': Icons.attach_money_rounded,
    'emoji': '💵',
  },
  {
    'value': 'High Stakes',
    'label': 'High Stakes',
    'icon': Icons.monetization_on_rounded,
    'emoji': '💰',
  },
];

const List<Map<String, dynamic>> kCreateGameHandicapOptions = [
  {
    'value': 'Gross',
    'label': 'Gross',
    'icon': Icons.sports_golf_rounded,
    'emoji': '📊',
  },
  {
    'value': 'Net',
    'label': 'Net',
    'icon': Icons.calculate_rounded,
    'emoji': '🧮',
  },
  {
    'value': 'Both',
    'label': 'Gross + Net',
    'icon': Icons.compare_arrows_rounded,
    'emoji': '↔️',
  },
];
