import 'age_verification.dart';
import 'exceptions.dart';
import 'poll_options.dart';
import 'transport.dart';

class FrejaAuthRequest {
  const FrejaAuthRequest({
    this.ssn,
    this.callbackUrl,
    this.minRegistrationLevel,
    this.orgNumber,
    this.requestAddress,
    this.refId,
  });

  final String? ssn;
  final String? callbackUrl;
  final String? minRegistrationLevel;
  final String? orgNumber;
  final bool? requestAddress;
  final String? refId;

  Map<String, dynamic> toJson() => {
        if (ssn != null) 'ssn': ssn,
        if (callbackUrl != null) 'callbackUrl': callbackUrl,
        if (minRegistrationLevel != null) 'minRegistrationLevel': minRegistrationLevel,
        if (orgNumber != null) 'orgNumber': orgNumber,
        if (requestAddress != null) 'requestAddress': requestAddress,
        if (refId != null) 'refId': refId,
      };
}

class FrejaBackchannelAuthRequest {
  const FrejaBackchannelAuthRequest({
    required this.ssn,
    required this.country,
    this.callbackUrl,
    this.minRegistrationLevel,
    this.orgNumber,
    this.requestAddress,
    this.refId,
  });

  final String ssn;
  final String country;
  final String? callbackUrl;
  final String? minRegistrationLevel;
  final String? orgNumber;
  final bool? requestAddress;
  final String? refId;

  Map<String, dynamic> toJson() => {
        'ssn': ssn,
        'country': country,
        if (callbackUrl != null) 'callbackUrl': callbackUrl,
        if (minRegistrationLevel != null) 'minRegistrationLevel': minRegistrationLevel,
        if (orgNumber != null) 'orgNumber': orgNumber,
        if (requestAddress != null) 'requestAddress': requestAddress,
        if (refId != null) 'refId': refId,
      };
}

class FrejaSignRequest {
  const FrejaSignRequest({
    required this.text,
    this.ssn,
    this.callbackUrl,
    this.minRegistrationLevel,
    this.orgNumber,
    this.requestAddress,
    this.refId,
  });

  final String text;
  final String? ssn;
  final String? callbackUrl;
  final String? minRegistrationLevel;
  final String? orgNumber;
  final bool? requestAddress;
  final String? refId;

  Map<String, dynamic> toJson() => {
        'text': text,
        if (ssn != null) 'ssn': ssn,
        if (callbackUrl != null) 'callbackUrl': callbackUrl,
        if (minRegistrationLevel != null) 'minRegistrationLevel': minRegistrationLevel,
        if (orgNumber != null) 'orgNumber': orgNumber,
        if (requestAddress != null) 'requestAddress': requestAddress,
        if (refId != null) 'refId': refId,
      };
}

class FrejaBackchannelSignRequest {
  const FrejaBackchannelSignRequest({
    required this.ssn,
    required this.country,
    required this.text,
    this.callbackUrl,
    this.minRegistrationLevel,
    this.orgNumber,
    this.requestAddress,
    this.refId,
  });

  final String ssn;
  final String country;
  final String text;
  final String? callbackUrl;
  final String? minRegistrationLevel;
  final String? orgNumber;
  final bool? requestAddress;
  final String? refId;

  Map<String, dynamic> toJson() => {
        'ssn': ssn,
        'country': country,
        'text': text,
        if (callbackUrl != null) 'callbackUrl': callbackUrl,
        if (minRegistrationLevel != null) 'minRegistrationLevel': minRegistrationLevel,
        if (orgNumber != null) 'orgNumber': orgNumber,
        if (requestAddress != null) 'requestAddress': requestAddress,
        if (refId != null) 'refId': refId,
      };
}

sealed class FrejaStatus {
  factory FrejaStatus.fromJson(Map<String, dynamic> json) => switch (json['status']) {
        'PENDING' => FrejaPending.fromJson(json),
        'COMPLETED' => FrejaCompleted.fromJson(json),
        'FAILED' => FrejaFailed.fromJson(json),
        _ => throw FormatException('Unknown freja status: ${json['status']}'),
      };
}

final class FrejaPending implements FrejaStatus {
  const FrejaPending({
    required this.id,
    this.refId,
    required this.autoStartToken,
    required this.qrData,
  });

  final String id;
  final String? refId;
  final String autoStartToken;
  final String qrData;

  factory FrejaPending.fromJson(Map<String, dynamic> json) => FrejaPending(
        id: json['id'] as String,
        refId: json['refId'] as String?,
        autoStartToken: json['autoStartToken'] as String,
        qrData: json['qrData'] as String,
      );
}

final class FrejaCompleted implements FrejaStatus {
  const FrejaCompleted({
    required this.id,
    this.refId,
    required this.ssn,
    required this.country,
    required this.name,
    required this.givenName,
    required this.surname,
    this.address,
    this.companySignatoryText,
  });

  final String id;
  final String? refId;
  final String ssn;
  final String country;
  final String name;
  final String givenName;
  final String surname;
  final String? address;
  final String? companySignatoryText;

  factory FrejaCompleted.fromJson(Map<String, dynamic> json) => FrejaCompleted(
        id: json['id'] as String,
        refId: json['refId'] as String?,
        ssn: json['ssn'] as String,
        country: json['country'] as String,
        name: json['name'] as String,
        givenName: json['givenName'] as String,
        surname: json['surname'] as String,
        address: json['address'] as String?,
        companySignatoryText: json['companySignatoryText'] as String?,
      );
}

final class FrejaFailed implements FrejaStatus {
  const FrejaFailed({required this.id, this.refId, required this.error});

  final String id;
  final String? refId;
  final String error;

  factory FrejaFailed.fromJson(Map<String, dynamic> json) => FrejaFailed(
        id: json['id'] as String,
        refId: json['refId'] as String?,
        error: json['error'] as String,
      );
}

class FrejaEndpoint {
  FrejaEndpoint(this._transport);
  final Transport _transport;

  Future<FrejaStatus> auth(FrejaAuthRequest req) async =>
      FrejaStatus.fromJson(await _transport.post('/v3/freja/auth', req.toJson()));
  Future<FrejaStatus> backchannelAuth(FrejaBackchannelAuthRequest req) async =>
      FrejaStatus.fromJson(await _transport.post('/v3/freja/backchannel/auth', req.toJson()));
  Future<FrejaStatus> sign(FrejaSignRequest req) async =>
      FrejaStatus.fromJson(await _transport.post('/v3/freja/sign', req.toJson()));
  Future<FrejaStatus> backchannelSign(FrejaBackchannelSignRequest req) async =>
      FrejaStatus.fromJson(await _transport.post('/v3/freja/backchannel/sign', req.toJson()));
  Future<FrejaStatus> authStatus(String id) async =>
      FrejaStatus.fromJson(await _transport.get('/v3/freja/auth/$id'));
  Future<FrejaStatus> signStatus(String id) async =>
      FrejaStatus.fromJson(await _transport.get('/v3/freja/sign/$id'));
  Future<void> cancelAuth(String id) => _transport.delete('/v3/freja/auth/$id');
  Future<void> cancelSign(String id) => _transport.delete('/v3/freja/sign/$id');
  Future<void> cancelAgeVerification(String id) => _transport.delete('/v3/freja/age-verification/$id');

  Future<FrejaStatus> waitForAuth(String id, {PollOptions opts = const PollOptions()}) =>
      _poll(() => authStatus(id), opts);
  Future<FrejaStatus> waitForSign(String id, {PollOptions opts = const PollOptions()}) =>
      _poll(() => signStatus(id), opts);

  Future<AgeVerificationStatus> ageVerification(AgeVerificationRequest req) async =>
      AgeVerificationStatus.fromJson(await _transport.post('/v3/freja/age-verification', req.toJson()));

  Future<AgeVerificationStatus> ageVerificationStatus(String id) async =>
      AgeVerificationStatus.fromJson(await _transport.get('/v3/freja/age-verification/$id'));

  Future<AgeVerificationStatus> waitForAgeVerification(String id, {PollOptions opts = const PollOptions()}) =>
      _pollAge(() => ageVerificationStatus(id), opts);

  Future<FrejaStatus> _poll(Future<FrejaStatus> Function() fn, PollOptions opts) async {
    final deadline = DateTime.now().add(opts.timeout);
    while (true) {
      final status = await fn();
      if (status is! FrejaPending) return status;
      if (DateTime.now().isAfter(deadline)) throw WaitException(timeout: true);
      await Future<void>.delayed(opts.interval);
    }
  }

  Future<AgeVerificationStatus> _pollAge(Future<AgeVerificationStatus> Function() fn, PollOptions opts) async {
    final deadline = DateTime.now().add(opts.timeout);
    while (true) {
      final status = await fn();
      if (status is! AgeVerificationPending) return status;
      if (DateTime.now().isAfter(deadline)) throw WaitException(timeout: true);
      await Future<void>.delayed(opts.interval);
    }
  }
}
