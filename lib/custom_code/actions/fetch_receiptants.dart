// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<List<DocumentReference>> fetchReceiptants(GamesRecord game) async {
  CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');

  List<DocumentReference> users = [];

  if (game.styleGame == 'Money Game') {
    QuerySnapshot moneyGameUsers =
        await userCollection.where('notify_money_game', isEqualTo: true).get();

    moneyGameUsers.docs.forEach((doc) {
      users.add(doc.reference);
    });
  }

  if (game.gameType == 'Vegas') {
    QuerySnapshot vegasGameUsers =
        await userCollection.where('notify_vegas_game', isEqualTo: true).get();

    vegasGameUsers.docs.forEach((doc) {
      users.add(doc.reference);
    });
  }

  if (game.rulesSetting == 'Competitive') {
    QuerySnapshot competitiveUsers = await userCollection
        .where('notify_competitive_game', isEqualTo: true)
        .get();
    competitiveUsers.docs.forEach((doc) {
      users.add(doc.reference);
    });
  }

  if (game.rulesSetting == 'For Fun') {
    QuerySnapshot forFunUsers =
        await userCollection.where('notify_for_fun', isEqualTo: true).get();
    forFunUsers.docs.forEach((doc) {
      users.add(doc.reference);
    });
  }

  if (game.friendGame == 'Friends') {
    QuerySnapshot friendUsers = await userCollection
        .where('notify_only_from_friends', isEqualTo: true)
        .get();
    friendUsers.docs.forEach((doc) {
      users.add(doc.reference);
    });
  }

  if (game.memberDiscount == 'Yes') {
    QuerySnapshot memberDiscountUsers = await userCollection
        .where('notify_member_discount', isEqualTo: true)
        .get();
    memberDiscountUsers.docs.forEach((doc) {
      users.add(doc.reference);
    });
  }

  return users;
}
