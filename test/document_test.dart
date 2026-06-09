import 'dart:convert';

import 'package:idkollen_client/idkollen_client.dart';
import 'package:test/test.dart';

import 'mock_client.dart';

void main() {
  late MockClient mock;
  late IdkollenClient client;

  setUp(() {
    mock = MockClient();
    client = IdkollenClientBuilder('cid', 'sec').baseUrl('https://x.test').httpClient(mock).build();
  });

  test('upload', () async {
    mock.enqueue(200, {'id': 'doc1', 'hash': 'h1'});
    final data = utf8.encode('PDF-DATA');
    final result = await client.document.upload(data, 'contract.pdf', mimeType: 'application/pdf');
    expect(result.id, 'doc1');
    expect(result.hash, 'h1');

    expect(mock.lastRequest.headers['Content-Type'], startsWith('multipart/form-data'));
    final body = mock.lastRequestBody;
    expect(body, contains('filename="contract.pdf"'));
    expect(body.toLowerCase(), contains('content-type: application/pdf'));
    expect(body, contains('PDF-DATA'));
  });

  test('download', () async {
    final expected = utf8.encode('\x25PDF-binary-bytes');
    mock.enqueue(200, '\x25PDF-binary-bytes');
    final result = await client.document.download('doc1');
    expect(result, expected);
  });

  test('delete', () async {
    mock.enqueue(204, '');
    await client.document.delete('doc1');
    expect(mock.lastRequest.method, 'DELETE');
    expect(mock.lastRequest.url.path, '/document/doc1');
  });
}
