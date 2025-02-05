import 'dart:convert';
import 'dart:developer';

enum ResponseType { json, xml, plain }

/// A response from the API, containing the actual response string and the status code
class Response {
  static const int statusCodeSuccess = 200;
  static const int statusCodeSuccessMax = 299;
  static const int statusCodeConnectionError = 9998;
  static const int statusCodeUnknownError = 9999;

  Map<String, dynamic>? _jsonData;
  String? _responseString;
  int _statusCode = statusCodeUnknownError;
  String? _errorMessage;
  // The transfer id can be passed to access it from the result, it is not used internally
  String? transferId;

  /// The response of an API request. If no parameters are passed, the response is considered an unknown error
  /// * [statusCode] - If no [responseString] is set, an error code can be provided.
  Response({String? responseString, ResponseType? responseType, int? statusCode, String? errorMessage}) {
    if (responseString != null) {
      _responseString = responseString;
      if (responseType == ResponseType.json) {
        _jsonData = json.decode(responseString);
      }
    }
    if (statusCode != null) _statusCode = statusCode;
    _errorMessage = errorMessage;
    if (_errorMessage != null || _statusCode < statusCodeSuccess || _statusCode > statusCodeSuccessMax) {
      log("Response error ($_statusCode): $_errorMessage\n$_responseString");
    }
  }

  /// Check if the request was successful
  bool success() {
    if (getStatusCode() >= statusCodeSuccess && getStatusCode() <= statusCodeSuccessMax) return true;
    return false;
  }

  /// Get the status code of the response
  /// Use success() to check if a request was successful
  int getStatusCode() {
    return _statusCode;
  }

  /// Get a specific element from the response
  /// Use for JSON responses, will return null for other response types
  dynamic getElement(String key) {
    return _jsonData?[key];
  }

  /// Get the complete response received from the server
  /// Use for plain text responses
  String? getResponseString() {
    return _responseString;
  }

  /// Get the error message the API returned
  String? getErrorMessage() {
    return _errorMessage;
  }
}
