class IdkollenException implements Exception {
  IdkollenException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'IdkollenException($statusCode): $message';
}

class WaitException implements Exception {
  WaitException({required this.timeout, this.cause});
  final bool timeout;
  final Object? cause;

  @override
  String toString() => timeout ? 'Poll timed out' : 'Poll error: $cause';
}
