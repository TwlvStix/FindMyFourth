import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/lat_lng.dart';
import '../models/place.dart';
import '../models/uploaded_file.dart';
import '/backend/backend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';

List<PostsRecord> getResultList(
  List<PostsRecord> mainList,
  List<PostsRecord> searchList,
) {
  return searchList.isNotEmpty ? searchList : mainList;
}

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
  return date != null ? date : null;
}

String errorImagePlaceholderURL() {
  return "https://plus.unsplash.com/premium_photo-1680553492268-516537c44d91?q=80&w=2940&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D";
}
