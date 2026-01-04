import '/components/date_format_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'join_game_detailed_widget.dart' show JoinGameDetailedWidget;
import 'package:flutter/material.dart';

class JoinGameDetailedModel extends FlutterFlowModel<JoinGameDetailedWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for DateFormat component.
  late DateFormatModel dateFormatModel;

  @override
  void initState(BuildContext context) {
    dateFormatModel = createModel(context, () => DateFormatModel());
  }

  @override
  void dispose() {
    dateFormatModel.dispose();
  }
}
