class IdentisureException implements Exception {
  IdentisureException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'IdentisureException($statusCode): $message';
}

class WaitException implements Exception {
  WaitException({required this.timeout, this.cause});
  final bool timeout;
  final Object? cause;

  @override
  String toString() => timeout ? 'Poll timed out' : 'Poll error: $cause';
}
