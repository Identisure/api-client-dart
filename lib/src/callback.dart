import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Verifies the `X-Signature-SHA256` header of a callback request.
///
/// Pass the raw request body exactly as received. Verify before parsing and
/// never re-serialize the JSON.
bool verifyCallbackSignature(List<int> body, String signature, String secret) {
  final List<int> expected;
  try {
    expected = base64.decode(signature);
  } on FormatException {
    return false;
  }

  final actual = Hmac(sha256, utf8.encode(secret)).convert(body).bytes;
  if (actual.length != expected.length) {
    return false;
  }

  var diff = 0;
  for (var i = 0; i < actual.length; i++) {
    diff |= actual[i] ^ expected[i];
  }
  return diff == 0;
}
