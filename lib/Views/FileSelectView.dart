import 'package:dac7_reporter/Service/SettingsManager.dart';
import 'package:flutter/material.dart';

import '../Service/FileSelectManager.dart';

/// Widget containing a label, textfield and a button, whichs opens a file select
class FileSelectView extends StatefulWidget {
  final FileSelectManager fileSelectManager;
  final TextEditingController textEditingController;
  final String label;

  const FileSelectView({
    super.key, required this.fileSelectManager, required this.textEditingController, required this.label
  });

  @override
  State<FileSelectView> createState() => _FileSelectViewState();
}

class _FileSelectViewState extends State<FileSelectView> {
  @override
  Widget build(BuildContext context) {
    var defaultPadding = SettingsManager.defaultPadding;
    var defaultFontSize = SettingsManager.defaultFontSize;
    return Container(
      margin: EdgeInsets.only(bottom: defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(fontSize: defaultFontSize, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Flexible(
                child: TextField(
                  style: TextStyle(fontSize: defaultFontSize),
                  enabled: false,
                  controller: widget.textEditingController
                ),
              ),

              Padding(
                padding: EdgeInsets.only(left: defaultPadding),
                child: TextButton(
                  onPressed: widget.fileSelectManager.showFileSelect, child: Text("Dateiauswahl")
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}