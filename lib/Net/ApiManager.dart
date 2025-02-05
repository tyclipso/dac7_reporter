import 'dart:math';

import 'package:dac7_reporter/Net/Request.dart';
import 'package:dac7_reporter/Net/Response.dart';
import 'package:dac7_reporter/Service/XmlManager.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// API communication with the German government server
class ApiManager {
  static const serverTest = 'mds-ktst.bzst.bund.de';
  static const serverLive = 'mds.bzst.bund.de';
  static final ApiManager _defaultManager = ApiManager();

  String clientId = "";
  bool liveMode = false;
  String? _accessToken;
  RSAPrivateKey? _rsaPrivKey;
  String? _rsaPrivKeyFile;
  RSAPublicKey? _certificate;
  String? _certificateFile;

  static ApiManager defaultManager() {
    return _defaultManager;
  }

  void setPrivateKey(String privateKey, String privateKeyFile) {
    _rsaPrivKey = RSAPrivateKey(privateKey);
    _rsaPrivKeyFile = privateKeyFile;
  }

  void setCertificate(String certificate, String certificateFile) {
    _certificate = RSAPublicKey.cert(certificate);
    _certificateFile = certificateFile;
  }

  RSAPrivateKey _getPrivateKey() {
    if (_rsaPrivKey == null) {
      throw Exception('Missing private key');
    }
    return _rsaPrivKey!;
  }

  RSAPublicKey _getCertificate() {
    if (_certificate == null) {
      throw Exception('Missing certificate');
    }
    return _certificate!;
  }

  /// Get the server depending on the test/live mode setting
  String _getServer() {
    if (liveMode) {
      return serverLive;
    }
    return serverTest;
  }

  /// Generate a random string as unique id for the JWT
  String _generateRandomString(int len) {
    var r = Random();
    return String.fromCharCodes(List.generate(len, (index) => r.nextInt(26) + 97));
  }

  /// Create a new JWT
  String _createJWT() {
      var userId = clientId;
      final newJwt = JWT({},
        subject: userId,
        issuer: userId,
        audience: Audience(["https://${_getServer()}/auth/realms/mds"]),
        jwtId: _generateRandomString(16)
      );
      var result = newJwt.sign(
        _getPrivateKey(),
        algorithm: JWTAlgorithm.RS256,
        notBefore: const Duration(hours: -1),
        expiresIn: const Duration(hours: 24)
      );
      JWT.verify(result, _getCertificate());
      return result;
  }

  /// Get a new token from the server
  Future<Response> _refreshToken() async {
    Response? response;
    try {
      String jwt = _createJWT();
      Request request = Request(
        server: _getServer(),
        endpoint: "/auth/realms/mds/protocol/openid-connect/token",
        requestMethod: RequestMethod.post
      );
      request.setParams({
        "grant_type": "client_credentials",
        "scope": "openid",
        "client_assertion_type": "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        "client_assertion": jwt,
      });
      response = await request.send();
    } catch (e) {
      response = Response(errorMessage: e.toString());
    }
    return response;
  }

  /// Get the bearer token for the API
  Future<String?> _getToken({bool forceNew = false}) async {
    if (_accessToken == null || forceNew) {
      var response = await _refreshToken();
      // Available elements: access_token, expires_in, refresh_expires_in, token_type, id_token, not-before-policy, scope
      if (response.success()) _accessToken = response.getElement("access_token");
    }
    return _accessToken;
  }

  /// Create a new transfer
  /// This will return a response with a transfer id, which we can use to transfer the actual data
  Future<Response> _initTransfer() async {
    Response? response;
    try {
      String? token = await _getToken(forceNew: true);
      Request request = Request(
        server: _getServer(),
        endpoint: "/dip/start/DAC7",
        token: token,
        requestMethod: RequestMethod.post,
        responseType: ResponseType.plain
      );
      response = await request.send();
    } catch (e) {
      response = Response(errorMessage: e.toString());
    }
    return response;
  }

  /// Transfer the XML data
  Future<Response> _transfer(String transferId, String xmlData) async {
    Response? response;
    try {
      String? token = await _getToken();
      Request request = Request(
        server: _getServer(),
        endpoint: "/dip/md/$transferId/xml",
        token: token,
        requestMethod: RequestMethod.put,
        responseType: ResponseType.plain
      );
      request.setBodyData(xmlData);
      response = await request.send();
    } catch (e) {
      response = Response(errorMessage: e.toString());
    }
    response.transferId = transferId;
    return response;
  }

  /// Finish the data submission
  Future<Response> _finishTransfer(String transferId) async {
    Response? response;
    try {
      String? token = await _getToken();
      Request request = Request(
        server: _getServer(),
        endpoint: "/dip/md/$transferId/finish",
        token: token,
        requestMethod: RequestMethod.patch,
        responseType: ResponseType.plain
      );
      response = await request.send();
    } catch (e) {
      response = Response(errorMessage: e.toString());
    }
    response.transferId = transferId;
    return response;
  }

  /// Fetch all protocols that are available
  /// This can be useful, if protocols from the API are heavily delayed, so you'll have to fetch them later
  Future<Response> fetchAllProtocols() async {
    Response? response;
    try {
      String? token = await _getToken(forceNew: true);
      Request request = Request(
          server: _getServer(),
          endpoint: "/dip/md/protocolnumbers",
          token: token,
          responseType: ResponseType.plain
      );
      response = await request.send();
    } catch (e) {
      response = Response(errorMessage: e.toString());
    }
    return response;
  }

  /// Fetch a single protocol
  Future<Response> fetchProtocol(String transferId) async {
    Response? response;
    try {
      String? token = await _getToken(forceNew: true);
      Request request = Request(
        server: _getServer(),
        endpoint: "/dip/md/$transferId/protocol",
        token: token,
        responseType: ResponseType.plain
      );
      response = await request.send();
    } catch (e) {
      response = Response(errorMessage: e.toString());
    }
    response.transferId = transferId;
    return response;
  }

  /// Upload the XML to the server
  /// If it does not contain a signature, it will be signed using the external Java application
  Future<Response> uploadXml(String originalXmlData, String originalXmlFile) async {
    Response? response;
    try {
      bool signXml = !originalXmlData.contains("<ds:Signature");
      if (signXml) {
        var signedXmlData = await XmlManager.defaultManager().signXml(originalXmlFile, _rsaPrivKeyFile!, _certificateFile!);
        if (signedXmlData != null) {
          originalXmlData = signedXmlData;
        } else {
          return Response(errorMessage: "Signatur konnte nicht erstellt werden");
        }
      }
      _accessToken = null;
      response = await _initTransfer();
      String? transferId = response.getResponseString();
      if (!response.success() || transferId == null) return response;
      response = await _transfer(transferId, originalXmlData);
      if (!response.success()) return response;
      response = await _finishTransfer(transferId);
      return response;
    } catch (e) {
      response = Response(errorMessage: e.toString());
    }
    return response;
  }
}