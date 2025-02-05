import 'package:shared_preferences/shared_preferences.dart';

/// Class for managing persistent settings
class SettingsManager {
  static const currentVersion = "1.0.0";
  static final SettingsManager _defaultManager = SettingsManager();
  static const settingClientId = "clientId";
  static const settingLiveServer = "liveServer";
  static double defaultPadding = 16;
  static double defaultFontSize = 14;

  String? lastTransferId;
  String statusText = "";

  Map<String, String?> _settings = {};

  static SettingsManager defaultManager() {
    return _defaultManager;
  }

  /// Shorthand for SettingsManager.defaultManager().getValue(sKey)
  static String? getV(String sKey) {
    return defaultManager().getValue(sKey);
  }

  /// Setup the default settings if they are not false/0/""
  Map<String, String?> _getDefaultSettings() {
    return {
      settingLiveServer: "0"
    };
  }

  /// Load all settings
  Future<bool> load() async {
    Map<String, String?> tempSettings = _getDefaultSettings();
    final prefs = await SharedPreferences.getInstance();
    // Go through all prefs and read them to the memory cache
    for (String sKey in prefs.getKeys()) {
      tempSettings[sKey] = prefs.getString(sKey);
    }
    _settings = tempSettings;
    return true;
  }

  /// Save all settings
  Future<bool> save() async {
    Map<String, bool> changedSettings = {};
    final prefs = await SharedPreferences.getInstance();
    // Go through all settings
    var keysCopy = List.from(_settings.keys);
    for (String sKey in keysCopy) {
      if (_settings[sKey] != null) {
        // Only store when changed since each change is stored separately
        if (prefs.getString(sKey) != _settings[sKey]) {
          await prefs.setString(sKey, _settings[sKey]!);
          changedSettings[sKey] = true;
        }
      } else {
        _settings.remove(sKey);
        await prefs.remove(sKey);
      }
    }
    return true;
  }

  String? getValue(String sKey) {
    return _settings[sKey];
  }

  setValue(String sKey, String? sValue) {
    _settings[sKey] = sValue;
  }

  bool getBoolValue(String sKey) {
    String? value = getValue(sKey);
    if (value == "1") return true;
    return false;
  }

  int getIntValue(String sKey) {
    String? value = getValue(sKey);
    if (value != null) {
      int? intValue = int.tryParse(value);
      if (intValue != null) {
        return intValue;
      }
    }
    return 0;
  }

  bool useTestServer() {
    return getBoolValue(settingLiveServer);
  }
}