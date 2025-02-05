import 'dart:developer';

import 'package:file_selector/file_selector.dart';

/// Shows a file select dialog
class FileSelectManager {
  void Function()? fileSelectionErrorCallback;
  void Function()? fileSelectionSuccessCallback;
  String? errorMessage;
  List<XFile> _selectedFiles = List.empty();
  bool removeExistingFile = false;

  /// Show file picker
  Future<bool> showFileSelect() async {
    errorMessage = null;
    try {
      List<XFile> files;
      XFile? file;
      file = await openFile(acceptedTypeGroups: <XTypeGroup>[const XTypeGroup()]);
      file != null ? files = [file] : files = [];
      _onFileSelectionSuccess(files);
    } catch (e) {
      _onFileSelectionError(e.toString());
    }
    return true;
  }

  List<XFile> getSelectedFiles() {
    return _selectedFiles;
  }

  /// Files were selected successfully
  void _onFileSelectionSuccess(List<XFile> xFiles) async {
    _selectedFiles = xFiles;
    if (fileSelectionSuccessCallback != null) fileSelectionSuccessCallback!();
  }

  /// There was an error selecting the files
  void _onFileSelectionError(String message) {
    _selectedFiles = List.empty();
    errorMessage = message;
    log(message);
    if (fileSelectionErrorCallback != null) fileSelectionErrorCallback!();
  }
}