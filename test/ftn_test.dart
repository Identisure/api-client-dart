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
      'id': 'f1',
      'url': 'https://login',
    });
    final result = await client.ftn.auth(const FtnAuthRequest());
    expect(result, isA<FtnPending>());
    expect((result as FtnPending).url, 'https://login');
  });

  test('unknown status', () async {
    mock.enqueue(200, {
      'status': 'SOMETHING_NEW',
      'id': 'f1',
    });
    final result = await client.ftn.authStatus('f1');
    expect(result, isA<FtnUnknown>());
    expect((result as FtnUnknown).status, 'SOMETHING_NEW');
  });

  test('age verification completed', () async {
    mock.enqueue(200, {
      'status': 'COMPLETED',
      'id': 'av1',
      'ageVerified': true,
    });
    final result = await client.ftn.ageVerificationStatus('av1');
    expect(result, isA<AgeVerificationCompleted>());
    expect((result as AgeVerificationCompleted).ageVerified, true);
  });
}
