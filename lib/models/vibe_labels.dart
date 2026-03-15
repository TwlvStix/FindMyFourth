import '/models/vibe_profile.dart';

class VibeLabels {
  static String titleFor(VibeCategory category) {
    switch (category) {
      case VibeCategory.chat:
        return 'Chat';
      case VibeCategory.pace:
        return 'Pace';
      case VibeCategory.money:
        return 'Money';
      case VibeCategory.drinking:
        return 'Drinking';
      case VibeCategory.music:
        return 'Music';
      case VibeCategory.competitive:
        return 'Competitive';
    }
  }

  static String promptFor(VibeCategory category) {
    return _prompts[category] ?? titleFor(category);
  }

  static String helperFor(VibeCategory category) {
    return _helpers[category] ?? '';
  }

  static String? labelFor(VibeCategory category, int value) {
    return _labels[category]?[value];
  }

  static const Map<VibeCategory, String> _prompts = {
    VibeCategory.drinking:
        'How do you feel about alcohol in your group during a round?',
    VibeCategory.music:
        'How do you feel about music being played during the round?',
    VibeCategory.chat:
        'How talkative do you like the group to be during the round?',
    VibeCategory.money:
        'How do you feel about gambling and side games (skins, presses, bets) in your group during a round?',
    VibeCategory.competitive:
        'How competitive do you like the group atmosphere to be?',
    VibeCategory.pace: 'How do you feel about pace expectations in your group?',
  };

  static const Map<VibeCategory, String> _helpers = {
    VibeCategory.drinking:
        "Rate what you're comfortable being around, not whether you personally drink.",
    VibeCategory.music:
        "Rate what you enjoy being around, even if you don't play music yourself.\nRespectful behavior matters. Rate what you enjoy being around.",
    VibeCategory.chat:
        "Rate the group energy you enjoy, not how talkative you are as a person.\nRespectful behavior matters. Rate what you enjoy being around.",
    VibeCategory.money:
        'Rate what you enjoy being around, not how much you personally bet.',
    VibeCategory.competitive:
        'Rate the competitive intensity you enjoy being around, not your skill level.',
    VibeCategory.pace:
        "Rate the pace you enjoy being around, not how fast you personally walk.\nRespectful behavior matters. Rate what you enjoy being around.",
  };

  static const Map<VibeCategory, Map<int, String>> _labels = {
    VibeCategory.pace: {
      0: 'I play deliberate. I read every putt.',
      1: 'No rush. I play at my own pace.',
      2: 'Keep it moving but I\'m not stressing.',
      3: 'Steady pace. I don\'t like waiting.',
      4: 'Ready golf. Let\'s go.',
      5: 'If you\'re not ready, I\'m hitting.',
    },
    VibeCategory.chat: {
      0: 'I keep to myself out there.',
      1: 'A few words here and there.',
      2: 'I\'ll chat between shots.',
      3: 'I like a good conversation on the course.',
      4: 'Bring the energy — stories, jokes, the whole round',
      5: 'Nonstop — talking is half the reason I\'m out here',
    },
    VibeCategory.music: {
      0: 'No music. I like the sounds of the course.',
      1: 'Low and quiet if anything.',
      2: 'Background music is fine.',
      3: 'I like music going most of the round.',
      4: 'Speaker\'s on from the first tee.',
      5: 'I\'ve got a playlist ready. It\'s non-negotiable.',
    },
    VibeCategory.drinking: {
      0: 'I don\'t drink on the course.',
      1: 'Maybe one, keep it light.',
      2: 'A couple beers through the round.',
      3: 'A drink in hand most of the round.',
      4: 'Cart girl every time. Cooler\'s stocked.',
      5: 'We\'re here to golf and drink. In that order. Maybe.',
    },
    VibeCategory.money: {
      0: 'No games, no bets. I\'m just playing golf.',
      1: 'A friendly bet for a beer or bragging rights.',
      2: 'Skins or dots. A few bucks to keep it interesting.',
      3: 'A few games running. Enough to make it sting a little.',
      4: 'Multiple games, real money. That\'s how I play.',
      5: 'Big stakes, big action. The bet makes the round.',
    },
    VibeCategory.competitive: {
      0: 'I\'m just out here having fun.',
      1: 'I don\'t really keep score.',
      2: 'I keep score for my own game and handicap.',
      3: 'I\'m trying to beat my group. Every time.',
      4: 'I secretly wish the worst for my playing partners.',
      5: 'Every shot feels like the Masters.',
    },
  };
}
