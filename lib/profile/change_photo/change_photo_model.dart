import '/core/app_util.dart';
import 'change_photo_widget.dart' show ChangePhotoWidget;
import 'package:flutter/material.dart';

class ChangePhotoModel extends AppModel<ChangePhotoWidget> {
  ///  State fields for stateful widgets in this component.

  bool isDataUploading_uploadDataJ3j = false;
  FFUploadedFile uploadedLocalFile_uploadDataJ3j =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataJ3j = '';

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
