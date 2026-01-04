import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'blog_edit_widget.dart' show BlogEditWidget;
import 'package:flutter/material.dart';

class BlogEditModel extends FlutterFlowModel<BlogEditWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for inputTitle widget.
  FocusNode? inputTitleFocusNode;
  TextEditingController? inputTitleTextController;
  String? Function(BuildContext, String?)? inputTitleTextControllerValidator;
  // State field(s) for inputContent widget.
  FocusNode? inputContentFocusNode;
  TextEditingController? inputContentTextController;
  String? Function(BuildContext, String?)? inputContentTextControllerValidator;
  bool isDataUploading_editPicNewsfeed = false;
  FFUploadedFile uploadedLocalFile_editPicNewsfeed =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_editPicNewsfeed = '';

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    inputTitleFocusNode?.dispose();
    inputTitleTextController?.dispose();

    inputContentFocusNode?.dispose();
    inputContentTextController?.dispose();
  }
}
