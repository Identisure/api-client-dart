import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class MockClient extends http.BaseClient {
  final List<({int status, String body})> _queue = [];
  final List<http.BaseRequest> requests = [];
  final List<String> requestBodies = [];

  void enqueue(int status, Object body) {
    final str = body is String ? body : jsonEncode(body);
    _queue.add((status: status, body: str));
  }

  http.BaseRequest get lastRequest => requests.last;
  String get lastRequestBody => requestBodies.last;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    String body = '';
    if (request is http.Request) {
      body = request.body;
    } else if (request is http.MultipartRequest) {
      // Buffer the multipart body for assertions.
      final completer = Completer<String>();
      final finalized = request.finalize();
      finalized.transform(utf8.decoder).join().then(completer.complete);
      body = await completer.future;
    }
    requestBodies.add(body);
    if (_queue.isEmpty) {
      throw StateError('No responses queued');
    }
    final item = _queue.removeAt(0);
    final bytes = utf8.encode(item.body);
    return http.StreamedResponse(
      Stream.value(bytes),
      item.status,
      contentLength: bytes.length,
    );
  }
}
