import 'package:dac7_reporter/Service/SettingsManager.dart';
import 'package:flutter/material.dart';

/// Widget to show the protocol of a transfer
class ProtocolViewController extends StatefulWidget {
  const ProtocolViewController({super.key, required this.protocol});
  final String? protocol;

  @override
  State<ProtocolViewController> createState() => _ProtocolViewControllerState();
}

class _ProtocolViewControllerState extends State<ProtocolViewController> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text("Protokoll"),
      ),
      body: Container(
        padding: EdgeInsets.all(SettingsManager.defaultPadding),
        child: SingleChildScrollView(
          child: SelectableText(widget.protocol ?? "")
        ),
      )
    );
  }

}