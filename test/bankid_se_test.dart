import 'dart:convert';

import 'package:identisure_client/identisure_client.dart';
import 'package:test/test.dart';

import 'mock_client.dart';

void main() {
  late MockClient mock;
  late IdentisureClient client;

  setUp(() {
    mock = MockClient();
    client = IdentisureClientBuilder('cid', 'sec')
        .baseUrl('https://x.test')
        .httpClient(mock)
        .build();
  });

  test('auth pending', () async {
    mock.enqueue(200, {
      'status': 'PENDING',
      'id': 'abc',
      'autoStartToken': 'tok',
    });
    final result = await client.bankIdSe.auth(const BankIdSeAuthRequest(ssn: '199001011234'));
    expect(result, isA<BankIdSePending>());
    final p = result as BankIdSePending;
    expect(p.id, 'abc');
    expect(p.autoStartToken, 'tok');

    final body = jsonDecode(mock.lastRequestBody) as Map<String, dynamic>;
    expect(body['ssn'], '199001011234');
  });

  test('auth completed', () async {
    mock.enqueue(200, {
      'status': 'COMPLETED',
      'id': 'abc',
      'ssn': '199001011234',
      'name': 'Test User',
      'givenName': 'Test',
      'surname': 'User',
      'ocspResponse': 'MIIB',
    });
    final result = await client.bankIdSe.auth(const BankIdSeAuthRequest());
    expect(result, isA<BankIdSeCompleted>());
    expect((result as BankIdSeCompleted).name, 'Test User');
  });

  test('auth failed', () async {
    mock.enqueue(200, {'status': 'FAILED', 'id': 'abc', 'error': 'CANCELLED'});
    final result = await client.bankIdSe.auth(const BankIdSeAuthRequest());
    expect(result, isA<BankIdSeFailed>());
    expect((result as BankIdSeFailed).error, 'CANCELLED');
  });

  test('phoneAuth pending', () async {
    mock.enqueue(200, {
      'status': 'PENDING',
      'id': 'abc',
      'hintCode': 'outstandingTransaction',
    });
    final result = await client.bankIdSe.phoneAuth(
      const BankIdSePhoneAuthRequest(ssn: '199001011234', callInitiator: 'USER'),
    );
    expect(result, isA<BankIdSePendingPhone>());
  });

  test('verify', () async {
    mock.enqueue(200, {
      'ssn': '199001011234',
      'name': 'Test User',
      'givenName': 'Test',
      'surname': 'User',
      'age': 34,
      'verifiedAt': '2026-06-08T10:00:00Z',
    });
    final result = await client.bankIdSe.verify(const BankIdSeVerifyRequest(qrCode: 'qr'));
    expect(result.age, 34);
  });

  test('cancelAuth sends DELETE', () async {
    mock.enqueue(204, '');
    await client.bankIdSe.cancelAuth('xyz');
    expect(mock.lastRequest.method, 'DELETE');
    expect(mock.lastRequest.url.path, '/v3/bankid-se/auth/xyz');
  });
}
