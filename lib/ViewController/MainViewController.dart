import 'package:dac7_reporter/Service/FileSelectManager.dart';
import 'package:dac7_reporter/Service/SettingsManager.dart';
import 'package:dac7_reporter/ViewController/ProtocolViewController.dart';
import 'package:flutter/material.dart';

import '../Net/ApiManager.dart';
import '../Views/FileSelectView.dart';

/// Widget containing the form to setup the API call
class MainViewController extends StatefulWidget {
  const MainViewController({super.key});

  @override
  State<MainViewController> createState() => _MainViewControllerState();
}

class _MainViewControllerState extends State<MainViewController> {
  final FileSelectManager _privateKeyFileManager = FileSelectManager();
  final FileSelectManager _certificateFileManager = FileSelectManager();
  final FileSelectManager _xmlFileManager = FileSelectManager();
  final TextEditingController _privateKeyTextController = TextEditingController();
  final TextEditingController _certificateTextController = TextEditingController();
  final TextEditingController _xmlTextController = TextEditingController();
  final TextEditingController _clientIdTextController = TextEditingController();
  String? _lastProtocol;

  @override
  void initState() {
    super.initState();
    _clientIdTextController.text = SettingsManager.defaultManager().getValue(SettingsManager.settingClientId) ?? "";
    _privateKeyFileManager.fileSelectionSuccessCallback = () => _fileSelected(_privateKeyFileManager, _privateKeyTextController);
    _certificateFileManager.fileSelectionSuccessCallback = () => _fileSelected(_certificateFileManager, _certificateTextController);
    _xmlFileManager.fileSelectionSuccessCallback = () => _fileSelected(_xmlFileManager, _xmlTextController);
  }

  Future<String?> _getSelectedFileContents(FileSelectManager fileManager) async {
    if (fileManager.getSelectedFiles().isNotEmpty) {
      var xmlFile = fileManager.getSelectedFiles().first;
      return xmlFile.readAsString();
    }
    return null;
  }

  void _fileSelected(FileSelectManager fileSelectManager, TextEditingController textController) {
    var files = fileSelectManager.getSelectedFiles();
    if (files.isNotEmpty) {
      var file = files.first;
      textController.text = file.path;
    } else {
      textController.text = "";
    }
    setState(() {});
  }

  void _modeToggleClick(bool newValue) {
    var sm = SettingsManager.defaultManager();
    sm.setValue(SettingsManager.settingLiveServer, newValue ? "1" : "0");
    sm.save();
    setState(() {});
  }

  void _sendButttonClick() async {
    var sm = SettingsManager.defaultManager();
    sm.setValue(SettingsManager.settingClientId, _clientIdTextController.text);
    sm.save();
    // Clear status
    sm.statusText = "Sende Daten...";
    String? xml = await _getSelectedFileContents(_xmlFileManager);
    String? privateKey = await _getSelectedFileContents(_privateKeyFileManager);
    String? certificate = await _getSelectedFileContents(_certificateFileManager);
    ApiManager.defaultManager().clientId = _clientIdTextController.text;
    ApiManager.defaultManager().liveMode = sm.getBoolValue(SettingsManager.settingLiveServer);
    if (xml != null && privateKey != null && certificate != null) {
      try {
        ApiManager.defaultManager().setPrivateKey(privateKey, _privateKeyFileManager.getSelectedFiles().first.path);
        ApiManager.defaultManager().setCertificate(certificate, _certificateFileManager.getSelectedFiles().first.path);
        sm.lastTransferId = null;
        _lastProtocol = null;
        var response = await ApiManager.defaultManager().uploadXml(xml, _xmlFileManager.getSelectedFiles().first.path);
        if (response.success() && response.transferId != null) {
          sm.lastTransferId = response.transferId;
          sm.save();
          sm.statusText = "Übertragung erfolgreich, TransferId: ${response.transferId}";
          setState(() {});
        } else {
          sm.statusText = response.getErrorMessage() ?? "";
        }
      } catch (e) {
        sm.statusText = "Fehler beim Absenden: ${e.toString()}";
      }
    } else {
      if (privateKey == null) {
        sm.statusText = "Bitte privaten Schlüssel auswählen!";
      } else if (certificate == null) {
        sm.statusText = "Bitte Zertifikat auswählen!";
      } else if (xml == null) {
        sm.statusText = "Bitte XML-Datei auswählen!";
      }
    }
    setState(() {});
  }

  void _fetchAllProtocols() async {
    var sm = SettingsManager.defaultManager();
    String? privateKey = await _getSelectedFileContents(_privateKeyFileManager);
    String? certificate = await _getSelectedFileContents(_certificateFileManager);
    ApiManager.defaultManager().clientId = _clientIdTextController.text;
    ApiManager.defaultManager().liveMode = sm.getBoolValue(SettingsManager.settingLiveServer);
    if (privateKey != null && certificate != null) {
      ApiManager.defaultManager().setPrivateKey(privateKey, _privateKeyFileManager.getSelectedFiles().first.path);
      ApiManager.defaultManager().setCertificate(certificate, _certificateFileManager.getSelectedFiles().first.path);
      sm.statusText = "Lade alle Protokolle...";
      setState(() {});
      var allTransfersResponse = await ApiManager.defaultManager().fetchAllProtocols();
      if (allTransfersResponse.success()) {
        String allResults = "";
        var xmlString = allTransfersResponse.getResponseString();
        if (xmlString != null) {
          final regex = RegExp(r'<Datentransfernummer>(.*)</Datentransfernummer>');
          var allMatches = regex.allMatches(xmlString);
          int i = 1;
          for (RegExpMatch transferIdMatch in allMatches) {
            var transferId = transferIdMatch.group(1);
            if (transferId != null) {
              sm.statusText = "Lade Protokoll $i von ${allMatches.length}";
              setState(() {});
              var response = await ApiManager.defaultManager().fetchProtocol(transferId);
              if (response.success()) {
                allResults = "${allResults}TransferId: $transferId\n\n${response.getResponseString()}\n------\n\n";
              }
            }
            ++i;
          }
          if (mounted) {
            sm.statusText = "";
            setState(() {});
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProtocolViewController(protocol: allResults))
            );
          }
        }
      }
    } else {
      if (privateKey == null) {
        sm.statusText = "Bitte privaten Schlüssel auswählen!";
      } else if (certificate == null) {
        sm.statusText = "Bitte Zertifikat auswählen!";
      }
    }
    setState(() {});
  }

  void _fetchProtocol() async {
    var sm = SettingsManager.defaultManager();
    var lastTransferId = SettingsManager.defaultManager().lastTransferId;
    if (lastTransferId != null) {
      if (_lastProtocol != null) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProtocolViewController(protocol: _lastProtocol))
          );
        }
      } else {
        sm.statusText = "Lade Protokoll für TransferId ${sm.lastTransferId}...";
        setState(() {});
        var response = await ApiManager.defaultManager().fetchProtocol(lastTransferId);
        if (response.success()) {
          sm.statusText = "Protokoll abgerufen für TransferId: ${sm.lastTransferId}";
          _lastProtocol = "TransferId: $lastTransferId\n\n${response.getResponseString()}";
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProtocolViewController(protocol: _lastProtocol))
            );
          }
        } else {
          sm.statusText = "Protokoll noch nicht verfügbar für TransferId: $lastTransferId";
        }
      }
    } else {
      sm.statusText = "Keine TransferId vorhanden für Protokollabfrage!";
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var lastTransferId = SettingsManager.defaultManager().lastTransferId;
    var liveServer = SettingsManager.defaultManager().getBoolValue(SettingsManager.settingLiveServer);
    var defaultPadding = SettingsManager.defaultPadding;
    var defaultFontSize = SettingsManager.defaultFontSize;
    double bottomBarHeight = 36;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("DAC7 Reporter"),
      ),
      body: Container(
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Client-ID",
                        style: TextStyle(fontSize: defaultFontSize, fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        style: TextStyle(fontSize: defaultFontSize),
                        controller: _clientIdTextController
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 2*defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Live Modus",
                        style: TextStyle(fontSize: defaultFontSize, fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Switch(value: liveServer, onChanged: _modeToggleClick)
                      )
                    ],
                  ),
                )
              ],
            ),
            Container(
              margin: EdgeInsets.only(bottom: defaultPadding),
            ),
            FileSelectView(
              label: "Privater Schlüssel (PEM Format)",
              fileSelectManager: _privateKeyFileManager,
              textEditingController: _privateKeyTextController,
            ),
            FileSelectView(
              label: "Zertifikat (PEM Format)",
              fileSelectManager: _certificateFileManager,
              textEditingController: _certificateTextController,
            ),
            FileSelectView(
              label: "XML",
              fileSelectManager: _xmlFileManager,
              textEditingController: _xmlTextController,
            )
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
            left: defaultPadding, right: defaultPadding, top: defaultPadding, bottom: bottomBarHeight + defaultPadding
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FloatingActionButton.extended(
              onPressed: _fetchAllProtocols,
              icon: Icon(Icons.receipt_long),
              label: Text("Alle Protokolle"),
              heroTag: "AllProtocolsButtonTag",
            ),
            if (lastTransferId != null) ...[
              FloatingActionButton.extended(
                onPressed: _fetchProtocol,
                icon: Icon(Icons.receipt_long),
                label: Text("Letztes Protokoll"),
                heroTag: "ProtocolButtonTag",
              ),
            ] else ... [
              // We need a dummy SizedBox to keep the other FAB at the right
              SizedBox()
            ],
            FloatingActionButton.extended(
              onPressed: _sendButttonClick,
              icon: Icon(Icons.send),
              label: Text("Absenden"),
              heroTag: "SendButtonTag",
            )
          ],
        )
      ), // This trailing comma makes auto-formatting nicer for build methods.
      bottomNavigationBar:
        Container(
          height: bottomBarHeight,
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: defaultPadding, right: defaultPadding),
              child: SelectableText(
                SettingsManager.defaultManager().statusText,
                maxLines: 1,
                style: TextStyle(
                  fontSize: defaultFontSize - 2,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary
                ),
              ),
            ),
          )
        ),
    );
  }
}