import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'player_list_widget.dart' show PlayerListWidget;
import 'package:flutter/material.dart';

class PlayerListModel extends FlutterFlowModel<PlayerListWidget> {
  ///  Local state fields for this page.

  List<DocumentReference> playersJoined = [];
  void addToPlayersJoined(DocumentReference item) => playersJoined.add(item);
  void removeFromPlayersJoined(DocumentReference item) =>
      playersJoined.remove(item);
  void removeAtIndexFromPlayersJoined(int index) =>
      playersJoined.removeAt(index);
  void insertAtIndexInPlayersJoined(int index, DocumentReference item) =>
      playersJoined.insert(index, item);
  void updatePlayersJoinedAtIndex(
          int index, Function(DocumentReference) updateFn) =>
      playersJoined[index] = updateFn(playersJoined[index]);

  List<String> playersJoinedUID = [];
  void addToPlayersJoinedUID(String item) => playersJoinedUID.add(item);
  void removeFromPlayersJoinedUID(String item) => playersJoinedUID.remove(item);
  void removeAtIndexFromPlayersJoinedUID(int index) =>
      playersJoinedUID.removeAt(index);
  void insertAtIndexInPlayersJoinedUID(int index, String item) =>
      playersJoinedUID.insert(index, item);
  void updatePlayersJoinedUIDAtIndex(int index, Function(String) updateFn) =>
      playersJoinedUID[index] = updateFn(playersJoinedUID[index]);

  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for DropDown widget.
  String? dropDownValue1;
  FormFieldController<String>? dropDownValueController1;
  // State field(s) for DropDown widget.
  String? dropDownValue2;
  FormFieldController<String>? dropDownValueController2;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
