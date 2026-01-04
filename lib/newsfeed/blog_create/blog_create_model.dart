import '/core/app_util.dart';
import '/index.dart';
import 'blog_create_widget.dart' show BlogCreateWidget;
import 'package:flutter/material.dart';

class BlogCreateModel extends AppModel<BlogCreateWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for inputTitle widget.
  FocusNode? inputTitleFocusNode;
  TextEditingController? inputTitleTextController;
  String? Function(BuildContext, String?)? inputTitleTextControllerValidator;
  // State field(s) for inputContent widget.
  FocusNode? inputContentFocusNode;
  TextEditingController? inputContentTextController;
  String? Function(BuildContext, String?)? inputContentTextControllerValidator;
  bool isDataUploading_createPicNewsfeed = false;
  FFUploadedFile uploadedLocalFile_createPicNewsfeed =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_createPicNewsfeed = '';

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
