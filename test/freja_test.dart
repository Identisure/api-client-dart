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
      'id': 'f1',
      'autoStartToken': 'tok',
      'qrData': 'qr',
    });
    final result = await client.freja.auth(const FrejaAuthRequest());
    expect(result, isA<FrejaPending>());
    expect((result as FrejaPending).qrData, 'qr');
  });

  test('auth completed', () async {
    mock.enqueue(200, {
      'status': 'COMPLETED',
      'id': 'f1',
      'ssn': '199001011234',
      'country': 'SE',
      'name': 'Test',
      'givenName': 'T',
      'surname': 'est',
    });
    final result = await client.freja.authStatus('f1');
    expect(result, isA<FrejaCompleted>());
    expect((result as FrejaCompleted).country, 'SE');
  });
}
