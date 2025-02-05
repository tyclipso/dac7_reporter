import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dac7_reporter/Net/Response.dart';

enum RequestMethod { get, patch, post, put, delete }

/// A request to the server
class Request {
  static const int connectionTimeout = 5;
  static const int responseTimeout = 20;
  // The same HttpClient is used for all requests
  static HttpClient? _sharedClient;

  // Private members
  final String _protocol = "https";
  final String _server;
  final String _endpoint;
  final RequestMethod _requestMethod;
  final ResponseType _responseType;
  final Map<String, String?> _parameters = {};
  String? _accessToken;
  String? _bodyData;

  /// Get the HttpClient for the request
  HttpClient _httpClient() {
    if (_sharedClient == null) {
      _sharedClient = HttpClient();
      _sharedClient!.connectionTimeout = const Duration(seconds: connectionTimeout);
    }
    return _sharedClient!;
  }

  Request({required String server, required String endpoint, RequestMethod? requestMethod, String? token, ResponseType? responseType}) :
    _requestMethod = requestMethod ?? RequestMethod.get,
    _endpoint = endpoint,
    _server = server,
    _accessToken = token,
    _responseType = responseType ?? ResponseType.json;

  /// Sets a parameter for this request
  ///
  /// * [pKey] - Name of the parameter
  /// * [pValue] - Value of the parameter
  void setParam(String pKey, String? pValue) {
    _parameters[pKey] = pValue;
  }

  void setBodyData(String bodyData) {
    _bodyData = bodyData;
  }

  /// Sets multiple parameters
  void setParams(Map<String, String> pMap) {
    for (String paramKey in pMap.keys) {
      if (pMap[paramKey] != null) _parameters[paramKey] = pMap[paramKey]!;
    }
  }

  /// Set the access token, which is required for most calls
  void setAccessToken(String? accessToken) {
    _accessToken = accessToken;
  }

  /// Add the authorization header to the request
  void _addAuthorizationHeader(HttpClientRequest request) {
    if (_accessToken != null) {
      request.headers.set("Authorization", "Bearer $_accessToken");
    }
  }

  /// Sends a request to the api
  ///
  /// * [returns] - The response from the API
  Future<Response> send() async {
    HttpClientRequest? request;
    try {
      log("api call: $_endpoint");
      if (_requestMethod == RequestMethod.post || _requestMethod == RequestMethod.put || _requestMethod == RequestMethod.patch) {
        // Create request
        Uri url = Uri(scheme: _protocol, host: _server, path: _endpoint);
        if (_requestMethod == RequestMethod.put) {
          request = await _httpClient().putUrl(url);
        } else if (_requestMethod == RequestMethod.patch) {
          request = await _httpClient().patchUrl(url);
        } else {
          request = await _httpClient().postUrl(url);
        }
        // Add default headers for API usage
        _addAuthorizationHeader(request);
        // Add post data
        String formBody = "";
        if (_bodyData != null) {
          formBody = _bodyData!;
          request.headers.contentType = ContentType("application", "octet-stream", charset: "utf-8");
        } else {
          var signedParams = _parameters;
          for (String mKey in signedParams.keys) {
            if (signedParams[mKey] != null) formBody += "$mKey=${Uri.encodeQueryComponent(signedParams[mKey]!)}&";
          }
          // Set content type
          request.headers.contentType = ContentType("application", "x-www-form-urlencoded", charset: "utf-8");
        }
        List<int> bodyBytes = utf8.encode(formBody); // utf8 encode
        // Additional post/put headers
        request.headers.set("Content-Length", bodyBytes.length.toString());
        request.add(bodyBytes);
      } else {
        Uri url = Uri(scheme: _protocol, host: _server, path: _endpoint, queryParameters: _parameters);
        if (_requestMethod == RequestMethod.delete) {
          request = await _httpClient().deleteUrl(url);
        } else {
          request = await _httpClient().getUrl(url);
        }
        // Add default headers for API usage
        _addAuthorizationHeader(request);
      }
      HttpClientResponse httpResponse = await request.close().timeout(const Duration(seconds: responseTimeout));
      final reponseString = await httpResponse.transform(utf8.decoder).join();
      var apiResponse = Response(responseString: reponseString, responseType: _responseType, statusCode: httpResponse.statusCode);
      return apiResponse;
    } on TimeoutException catch (e) {
      if (request != null) request.abort();
      return Response(statusCode: Response.statusCodeConnectionError, errorMessage: e.message);
    } on SocketException catch (e) {
      return Response(statusCode: Response.statusCodeConnectionError, errorMessage: e.message);
    }
  }
}
