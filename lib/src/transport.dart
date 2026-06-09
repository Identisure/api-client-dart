import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'exceptions.dart';

class Transport {
  Transport({
    required http.Client httpClient,
    required String baseUrl,
    required String clientId,
    required String clientSecret,
  })  : _http = httpClient,
        _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        _authHeader = 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}';

  static const _userAgent = 'idkollen-client-dart/0.1.0';

  final http.Client _http;
  final String _baseUrl;
  final String _authHeader;

  void close() => _http.close();

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
    req.headers['Authorization'] = _authHeader;
    req.headers['User-Agent'] = _userAgent;
    req.files.add(http.MultipartFile.fromBytes(
      'file',
      data,
      filename: filename,
      contentType: MediaType.parse(mimeType),
    ));
    final streamed = await _http.send(req);
    final res = await http.Response.fromStream(streamed);
    _ensureOk(res);
    return _decodeJson(res);
  }

  Future<http.Response> _send(http.Request req) async {
    req.headers['Authorization'] = _authHeader;
    req.headers['User-Agent'] = _userAgent;
    http.Response res;
    try {
      final streamed = await _http.send(req);
      res = await http.Response.fromStream(streamed);
    } on http.ClientException catch (e) {
      throw IdkollenException(0, e.message);
    }
    _ensureOk(res);
    return res;
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String message;
      try {
        final decoded = jsonDecode(res.body);
        message = (decoded is Map && decoded['message'] is String) ? decoded['message'] as String : res.body;
      } catch (_) {
        message = res.body;
      }
      throw IdkollenException(res.statusCode, message);
    }
  }

  Map<String, dynamic> _decodeJson(http.Response res) {
    if (res.body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(res.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }
}
