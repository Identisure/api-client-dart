import 'dart:convert';

import 'package:identisure_client/identisure_client.dart';
import 'package:test/test.dart';

void main() {
  const body = '{"id":"abc","status":"COMPLETED"}';
  const signature = 'Ag2m3etnW31OP585jvcrvOupK7Vgsrzcq17KxKvkIOs=';
  const secret = 'test-secret';

  test('valid signature', () {
    expect(
        verifyCallbackSignature(utf8.encode(body), signature, secret), isTrue);
  });

  test('tampered body', () {
    final tampered = utf8.encode('{"id":"abc","status":"FAILED"}');
    expect(verifyCallbackSignature(tampered, signature, secret), isFalse);
  });

  test('malformed signature', () {
    expect(verifyCallbackSignature(utf8.encode(body), 'not base64!', secret),
        isFalse);
  });
}
