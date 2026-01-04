import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'create_game_widget.dart' show CreateGameWidget;
import 'package:flutter/material.dart';

class CreateGameModel extends FlutterFlowModel<CreateGameWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // State field(s) for game_name widget.
  FocusNode? gameNameFocusNode;
  TextEditingController? gameNameTextController;
  String? Function(BuildContext, String?)? gameNameTextControllerValidator;
  String? _gameNameTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Field is required';
    }

    return null;
  }

  DateTime? datePicked;
  // State field(s) for Friends widget.
  String? friendsValue;
  FormFieldController<String>? friendsValueController;
  // State field(s) for course widget.
  String? courseValue;
  FormFieldController<String>? courseValueController;
  // Stores action output result for [Firestore Query - Query a collection] action in course widget.
  CourseRecord? selectedCourse;
  // State field(s) for member widget.
  String? memberValue;
  FormFieldController<String>? memberValueController;
  // State field(s) for CountController widget.
  int? countControllerValue;
  // State field(s) for rules_set widget.
  String? rulesSetValue;
  FormFieldController<String>? rulesSetValueController;
  // State field(s) for style_game widget.
  String? styleGameValue;
  FormFieldController<String>? styleGameValueController;
  // State field(s) for game_type widget.
  String? gameTypeValue;
  FormFieldController<String>? gameTypeValueController;
  // State field(s) for scoring widget.
  String? scoringValue;
  FormFieldController<String>? scoringValueController;
  // Stores action output result for [Backend Call - Create Document] action in Button widget.
  ChatsRecord? newChat;
  // Stores action output result for [Backend Call - Create Document] action in Button widget.
  GamesRecord? gameRef;
  // Stores action output result for [Custom Action - fetchReceiptants] action in Button widget.
  List<DocumentReference>? notifyUsers;

  @override
  void initState(BuildContext context) {
    gameNameTextControllerValidator = _gameNameTextControllerValidator;
  }

  @override
  void dispose() {
    gameNameFocusNode?.dispose();
    gameNameTextController?.dispose();
  }
}
