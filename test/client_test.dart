import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:idkollen_client/idkollen_client.dart';
import 'package:idkollen_client/src/transport.dart';
import 'package:test/test.dart';

import 'mock_client.dart';

void main() {
  test('builder produces a client', () {
    final client = IdkollenClientBuilder('id', 'secret')
        .environment(Environment.staging)
        .build();
    expect(client, isNotNull);
    client.close();
  });

  test('transport attaches Basic auth and User-Agent', () async {
    final mock = MockClient();
    mock.enqueue(200, {'ok': true});
    final transport = Transport(
      httpClient: mock,
      baseUrl: 'https://example.test',
      clientId: 'cid',
      clientSecret: 'sec',
    );

    await transport.get('/v3/ping');

    expect(mock.lastRequest.headers['Authorization'], 'Basic Y2lkOnNlYw==');
    expect(mock.lastRequest.headers['User-Agent'], contains('idkollen-client-dart/'));
    expect(mock.lastRequest.url.toString(), 'https://example.test/v3/ping');
  });

  test('non-2xx throws IdkollenException', () async {
    final mock = MockClient();
    mock.enqueue(400, {'message': 'bad request'});
    final transport = Transport(
      httpClient: mock,
      baseUrl: 'https://x.test',
      clientId: 'a',
      clientSecret: 'b',
    );

    expect(
      () => transport.post('/v3/things', {'a': 1}),
      throwsA(isA<IdkollenException>()
          .having((e) => e.statusCode, 'statusCode', 400)
          .having((e) => e.message, 'message', 'bad request')),
    );
  });

  test('request timeout throws IdkollenException', () async {
    final transport = Transport(
      httpClient: _HangingClient(),
      baseUrl: 'https://x.test',
      clientId: 'a',
      clientSecret: 'b',
      requestTimeout: const Duration(milliseconds: 10),
    );

    expect(
      () => transport.get('/v3/ping'),
      throwsA(isA<IdkollenException>().having((e) => e.statusCode, 'statusCode', 0)),
    );
  });
}

class _HangingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => Completer<http.StreamedResponse>().future;
}
