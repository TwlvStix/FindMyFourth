import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'newsfeed_widget.dart' show NewsfeedWidget;
import 'package:flutter/material.dart';

class NewsfeedModel extends FlutterFlowModel<NewsfeedWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for inputSearch widget.
  FocusNode? inputSearchFocusNode;
  TextEditingController? inputSearchTextController;
  String? Function(BuildContext, String?)? inputSearchTextControllerValidator;
  List<PostsRecord> simpleSearchResults = [];

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    inputSearchFocusNode?.dispose();
    inputSearchTextController?.dispose();
  }
}
