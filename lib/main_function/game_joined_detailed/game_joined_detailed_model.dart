import '/components/date_format_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'game_joined_detailed_widget.dart' show GameJoinedDetailedWidget;
import 'package:flutter/material.dart';

class GameJoinedDetailedModel
    extends FlutterFlowModel<GameJoinedDetailedWidget> {
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
