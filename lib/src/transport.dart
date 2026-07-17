import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'exceptions.dart';

class Transport {
  Transport({
    http.Client? httpClient,
    required String baseUrl,
    required String clientId,
    required String clientSecret,
  })  : _http = httpClient ?? http.Client(),
        _ownsHttp = httpClient == null,
        _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        _authHeader = 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}';

  static const _userAgent = 'idkollen-client-dart/0.1.0';
  static const _requestTimeout = Duration(seconds: 30);

  final http.Client _http;
  final bool _ownsHttp;
  final String _baseUrl;
  final String _authHeader;

  void close() {
    if (_ownsHttp) _http.close();
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final res = await _send(http.Request('POST', Uri.parse('$_baseUrl$path'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(body));
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final res = await _send(http.Request('GET', Uri.parse('$_baseUrl$path')));
    return _decodeJson(res);
  }

  Future<List<int>> getRaw(String path) async {
    final res = await _send(http.Request('GET', Uri.parse('$_baseUrl$path')));
    return res.bodyBytes;
  }

  Future<void> delete(String path) async {
    await _send(http.Request('DELETE', Uri.parse('$_baseUrl$path')));
  }

  Future<Map<String, dynamic>> postMultipart(
      String path, List<int> data, String filename, String mimeType) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'));
    req.files.add(http.MultipartFile.fromBytes(
      'file',
      data,
      filename: filename,
      contentType: MediaType.parse(mimeType),
    ));
    return _decodeJson(await _send(req));
  }

  Future<http.Response> _send(http.BaseRequest req) async {
    req.headers['Authorization'] = _authHeader;
    req.headers['User-Agent'] = _userAgent;
    http.Response res;
    try {
      final streamed = await _http.send(req).timeout(_requestTimeout);
      res = await http.Response.fromStream(streamed).timeout(_requestTimeout);
    } on http.ClientException catch (e) {
      throw IdkollenException(0, e.message);
    } on TimeoutException {
      throw IdkollenException(0, 'Request timed out after ${_requestTimeout.inSeconds} s');
    }
    _ensureOk(res);
    return res;
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String message;
      try {
        final decoded = jsonDecode(_bodyText(res));
        message = (decoded is Map && decoded['message'] is String) ? decoded['message'] as String : _bodyText(res);
      } catch (_) {
        message = _bodyText(res);
      }
      throw IdkollenException(res.statusCode, message);
    }
  }

  Map<String, dynamic> _decodeJson(http.Response res) {
    if (res.bodyBytes.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(_bodyText(res));
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  // JSON is UTF-8 (RFC 8259), but res.body falls back to Latin-1 when Content-Type has no charset.
  String _bodyText(http.Response res) => utf8.decode(res.bodyBytes, allowMalformed: true);
}
