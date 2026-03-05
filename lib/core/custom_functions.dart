import '/backend/backend.dart';
import '/core/utils/app_log.dart';

bool usernameChecker(
  String textfield,
  List<String> usernames,
) {
  return !usernames.contains(textfield);
}

String usernameCreator(String username) {
  return username.replaceAll(' ', '').toLowerCase();
}

/// Converts a user UID string to a DocumentReference.
/// Accepts optional [firestore] parameter for testability.
DocumentReference? returnDocRefFromUID(
  String? data, {
  FirebaseFirestore? firestore,
}) {
  if (data == null) {
    return null;
  }
  final fs = firestore ?? FirebaseFirestore.instance;
  return fs.collection('users').doc(data);
}

List<GamesRecord>? filterFunction(
  List<GamesRecord>? gamesList,
  String? choiceChipValue,
) {
  if (gamesList == null) {
    AppLog.d('📖 filterFunction: gamesList is null, returning empty');
    return [];
  }

  AppLog.d(
      '📖 filterFunction: received ${gamesList.length} games, filter=$choiceChipValue');

  // Default to showing all games if no filter is selected or filter is 'All'
  if (choiceChipValue == null || choiceChipValue == 'All') {
    AppLog.d('📖 filterFunction: returning all ${gamesList.length} games');
    return gamesList;
  }

  List<GamesRecord> filteredList = [];
  if (choiceChipValue == '\$\$\$\$') {
    filteredList =
        gamesList.where((game) => game.styleGame == 'Money Game').toList();
  } else if (choiceChipValue == 'Vegas') {
    filteredList = gamesList.where((game) => game.gameType == 'Vegas').toList();
  } else if (choiceChipValue == 'For Fun') {
    filteredList =
        gamesList.where((game) => game.styleGame == 'All Fun').toList();
  } else if (choiceChipValue == 'Discount') {
    filteredList =
        gamesList.where((game) => game.memberDiscount == 'Yes').toList();
  } else {
    // If unknown filter value, default to showing all games
    AppLog.d(
        '⚠️ filterFunction: unknown filter "$choiceChipValue", showing all games');
    filteredList = gamesList;
  }
  AppLog.d('📖 filterFunction: returning ${filteredList.length} filtered games');
  return filteredList;
}

DateTime? getCurrentTime() {
  return DateTime.now();
}

DateTime? nullableDatetiume(DateTime? date) {
  return date;
}

