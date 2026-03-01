import 'package:flutter/material.dart';
import '/backend/backend.dart';

bool usernameChecker(
  String textfield,
  List<String> usernames,
) {
  return !usernames.contains(textfield);
}

String usernameCreator(String username) {
  return username.replaceAll(' ', '').toLowerCase();
}

DocumentReference? returnDocRefFromUID(String? data) {
  if (data == null) {
    return null;
  }
  return FirebaseFirestore.instance.collection('users').doc(data);
}

List<GamesRecord>? filterFunction(
  List<GamesRecord>? gamesList,
  String? choiceChipValue,
) {
  if (gamesList == null) {
    debugPrint('filterFunction: gamesList is null, returning empty');
    return [];
  }

  debugPrint(
      'filterFunction: received ${gamesList.length} games, filter=$choiceChipValue');

  // Default to showing all games if no filter is selected or filter is 'All'
  if (choiceChipValue == null || choiceChipValue == 'All') {
    debugPrint('filterFunction: returning all ${gamesList.length} games');
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
    debugPrint(
        'filterFunction: unknown filter "$choiceChipValue", showing all games');
    filteredList = gamesList;
  }
  debugPrint('filterFunction: returning ${filteredList.length} filtered games');
  return filteredList;
}

DateTime? getCurrentTime() {
  return DateTime.now();
}

DateTime? nullableDatetiume(DateTime? date) {
  return date;
}

