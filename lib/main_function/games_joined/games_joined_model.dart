import '/backend/backend.dart';
import '/core/app_util.dart';
import '/index.dart';
import 'games_joined_widget.dart' show GamesJoinedWidget;
import 'package:flutter/material.dart';

class GamesJoinedModel extends AppModel<GamesJoinedWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Read Document] action in IconButton widget.
  ChatsRecord? chat;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
