import 'package:dac7_reporter/ViewController/Application.dart';
import 'package:flutter/material.dart';

import 'Service/SettingsManager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsManager.defaultManager().load();
  runApp(const Application());
}

