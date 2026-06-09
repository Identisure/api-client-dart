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

  test('auth pending', () async {
    mock.enqueue(200, {'status': 'PENDING', 'id': 'v1', 'url': 'https://vipps.login'});
    final result = await client.vipps.auth(const VippsAuthRequest(requestSsn: true));
    expect(result, isA<VippsPending>());
    expect((result as VippsPending).url, 'https://vipps.login');
  });

  test('backchannelAuth sends phone', () async {
    mock.enqueue(200, {'status': 'PENDING', 'id': 'v2'});
    await client.vipps.backchannelAuth(
      const VippsBackchannelAuthRequest(phone: '+4712345678'),
    );
    final body = jsonDecode(mock.lastRequestBody) as Map<String, dynamic>;
    expect(body['phone'], '+4712345678');
  });
}
