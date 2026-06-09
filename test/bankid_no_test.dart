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
    mock.enqueue(200, {'status': 'PENDING', 'id': 'no1', 'url': 'https://login'});
    final result = await client.bankIdNo.auth(const BankIdNoAuthRequest(requestSsn: true));
    expect(result, isA<BankIdNoPending>());
    expect((result as BankIdNoPending).url, 'https://login');
  });

  test('auth completed with signed documents', () async {
    mock.enqueue(200, {
      'status': 'COMPLETED',
      'id': 'no1',
      'ssn': '01010100000',
      'name': 'Ola Nordmann',
      'givenName': 'Ola',
      'surname': 'Nordmann',
      'signedDocuments': [
        {'id': 'd1', 'hash': 'h1'},
        {'id': 'd2', 'hash': 'h2'},
      ],
    });
    final result = await client.bankIdNo.authStatus('no1');
    expect(result, isA<BankIdNoCompleted>());
    final done = result as BankIdNoCompleted;
    expect(done.signedDocuments?.length, 2);
    expect(done.signedDocuments?[0].id, 'd1');
  });
}
