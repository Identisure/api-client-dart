import 'age_verification.dart';
import 'exceptions.dart';
import 'poll_options.dart';
import 'transport.dart';

// --- Request types ---

class FtnAuthRequest {
  const FtnAuthRequest({
    this.redirectUrl,
    this.requestPhone,
    this.requestEmail,
    this.requestAddress,
    this.refId,
  });

  final String? redirectUrl;
  final bool? requestPhone;
  final bool? requestEmail;
  final bool? requestAddress;
  final String? refId;

  Map<String, dynamic> toJson() => {
        if (redirectUrl != null) 'redirectUrl': redirectUrl,
        if (requestPhone != null) 'requestPhone': requestPhone,
        if (requestEmail != null) 'requestEmail': requestEmail,
        if (requestAddress != null) 'requestAddress': requestAddress,
        if (refId != null) 'refId': refId,
      };
}

// --- Status sealed classes ---

sealed class FtnStatus {
  factory FtnStatus.fromJson(Map<String, dynamic> json) => switch (json['status']) {
        'PENDING' => FtnPending.fromJson(json),
        'COMPLETED' => FtnCompleted.fromJson(json),
        'FAILED' => FtnFailed.fromJson(json),
        _ => throw FormatException('Unknown ftn status: ${json['status']}'),
      };
}

final class FtnPending implements FtnStatus {
  const FtnPending({required this.id, this.refId, required this.url});

  final String id;
  final String? refId;
  final String url;

  factory FtnPending.fromJson(Map<String, dynamic> json) => FtnPending(
        id: json['id'] as String,
        refId: json['refId'] as String?,
        url: json['url'] as String,
      );
}

final class FtnCompleted implements FtnStatus {
  const FtnCompleted({
    required this.id,
    this.refId,
    required this.ssn,
    required this.name,
    required this.givenName,
    required this.surname,
    this.phone,
    this.email,
    this.address,
    this.birthDate,
    this.pid,
    this.bankId,
  });

  final String id;
  final String? refId;
  final String ssn;
  final String name;
  final String givenName;
  final String surname;
  final String? phone;
  final String? email;
  final String? address;
  final String? birthDate;
  final String? pid;
  final String? bankId;

  factory FtnCompleted.fromJson(Map<String, dynamic> json) => FtnCompleted(
        id: json['id'] as String,
        refId: json['refId'] as String?,
        ssn: json['ssn'] as String,
        name: json['name'] as String,
        givenName: json['givenName'] as String,
        surname: json['surname'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        address: json['address'] as String?,
        birthDate: json['birthDate'] as String?,
        pid: json['pid'] as String?,
        bankId: json['bankId'] as String?,
      );
}

final class FtnFailed implements FtnStatus {
  const FtnFailed({required this.id, this.refId, required this.error});

  final String id;
  final String? refId;
  final String error;

  factory FtnFailed.fromJson(Map<String, dynamic> json) => FtnFailed(
        id: json['id'] as String,
        refId: json['refId'] as String?,
        error: json['error'] as String,
      );
}

// --- Endpoint ---

class FtnEndpoint {
  FtnEndpoint(this._transport);
  final Transport _transport;

  Future<FtnStatus> auth(FtnAuthRequest req) async =>
      FtnStatus.fromJson(await _transport.post('/v3/ftn/auth', req.toJson()));

  Future<AgeVerificationStatus> ageVerification(AgeVerificationRequest req) async =>
      AgeVerificationStatus.fromJson(await _transport.post('/v3/ftn/age-verification', req.toJson()));

  Future<FtnStatus> authStatus(String id) async =>
      FtnStatus.fromJson(await _transport.get('/v3/ftn/auth/$id'));

  Future<AgeVerificationStatus> ageVerificationStatus(String id) async =>
      AgeVerificationStatus.fromJson(await _transport.get('/v3/ftn/age-verification/$id'));

  Future<void> cancelAuth(String id) => _transport.delete('/v3/ftn/auth/$id');

  Future<void> cancelAgeVerification(String id) =>
      _transport.delete('/v3/ftn/age-verification/$id');

  Future<FtnStatus> waitForAuth(String id, {PollOptions opts = const PollOptions()}) =>
      _pollFtn(() => authStatus(id), opts);

  Future<AgeVerificationStatus> waitForAgeVerification(
          String id, {PollOptions opts = const PollOptions()}) =>
      _pollAge(() => ageVerificationStatus(id), opts);

  Future<FtnStatus> _pollFtn(Future<FtnStatus> Function() fn, PollOptions opts) async {
    final deadline = DateTime.now().add(opts.timeout);
    while (true) {
      final status = await fn();
      if (status is! FtnPending) return status;
      if (DateTime.now().isAfter(deadline)) throw WaitException(timeout: true);
      await Future<void>.delayed(opts.interval);
    }
  }

  Future<AgeVerificationStatus> _pollAge(
      Future<AgeVerificationStatus> Function() fn, PollOptions opts) async {
    final deadline = DateTime.now().add(opts.timeout);
    while (true) {
      final status = await fn();
      if (status is! AgeVerificationPending) return status;
      if (DateTime.now().isAfter(deadline)) throw WaitException(timeout: true);
      await Future<void>.delayed(opts.interval);
    }
  }
}
