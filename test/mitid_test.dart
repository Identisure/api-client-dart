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
    mock.enqueue(200, {
      'status': 'PENDING',
      'id': 'm1',
      'url': 'https://mitid.example/start',
    });
    final result = await client.mitId.auth(const MitIdAuthRequest());
    expect(result, isA<MitIdPending>());
    expect((result as MitIdPending).id, 'm1');
  });

  test('sign completed with sign result', () async {
    mock.enqueue(200, {
      'status': 'COMPLETED',
      'id': 'm2',
      'ssn': '1234567890',
      'name': 'Test User',
      'givenName': 'Test',
      'surname': 'User',
      'signResult': {'checksum': 'abc123'},
    });
    final result = await client.mitId.signStatus('m2');
    expect(result, isA<MitIdCompleted>());
    expect((result as MitIdCompleted).signResult?.checksum, 'abc123');
  });
}
