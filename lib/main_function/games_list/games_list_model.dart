import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'games_list_widget.dart' show GamesListWidget;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class GamesListModel extends FlutterFlowModel<GamesListWidget> {
  ///  Local state fields for this page.

  List<GamesRecord> filteredList = [];
  void addToFilteredList(GamesRecord item) => filteredList.add(item);
  void removeFromFilteredList(GamesRecord item) => filteredList.remove(item);
  void removeAtIndexFromFilteredList(int index) => filteredList.removeAt(index);
  void insertAtIndexInFilteredList(int index, GamesRecord item) =>
      filteredList.insert(index, item);
  void updateFilteredListAtIndex(int index, Function(GamesRecord) updateFn) =>
      filteredList[index] = updateFn(filteredList[index]);

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Firestore Query - Query a collection] action in GamesList widget.
  List<GamesRecord>? snapshotGames;
  // State field(s) for ChoiceChips widget.
  FormFieldController<List<String>>? choiceChipsValueController;
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
