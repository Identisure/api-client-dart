import 'age_verification.dart';
import 'exceptions.dart';
import 'poll_options.dart';
import 'transport.dart';

// --- Request types ---

class BankIdSeAuthRequest {
  const BankIdSeAuthRequest({
    this.ssn,
    this.ipAddress,
    this.callbackUrl,
    this.pinRequired,
    this.intent,
    this.orgNumber,
    this.requestAddress,
    this.refId,
  });

  final String? ssn;
  final String? ipAddress;
  final String? callbackUrl;
  final bool? pinRequired;
  final String? intent;
  final String? orgNumber;
  final bool? requestAddress;
  final String? refId;

  Map<String, dynamic> toJson() => {
        if (ssn != null) 'ssn': ssn,
        if (ipAddress != null) 'ipAddress': ipAddress,
        if (callbackUrl != null) 'callbackUrl': callbackUrl,
        if (pinRequired != null) 'pinRequired': pinRequired,
        if (intent != null) 'intent': intent,
        if (orgNumber != null) 'orgNumber': orgNumber,
        if (requestAddress != null) 'requestAddress': requestAddress,
        if (refId != null) 'refId': refId,
      };
}

class BankIdSePhoneAuthRequest {
  const BankIdSePhoneAuthRequest({
    required this.ssn,
    required this.callInitiator,
    this.callbackUrl,
    this.pinRequired,
    this.intent,
    this.orgNumber,
    this.requestAddress,
    this.refId,
  });

  final String ssn;
  final String callInitiator;
  final String? callbackUrl;
  final bool? pinRequired;
  final String? intent;
  final String? orgNumber;
  final bool? requestAddress;
  final String? refId;

  Map<String, dynamic> toJson() => {
        'ssn': ssn,
        'callInitiator': callInitiator,
        if (callbackUrl != null) 'callbackUrl': callbackUrl,
        if (pinRequired != null) 'pinRequired': pinRequired,
        if (intent != null) 'intent': intent,
        if (orgNumber != null) 'orgNumber': orgNumber,
        if (requestAddress != null) 'requestAddress': requestAddress,
        if (refId != null) 'refId': refId,
      };
}

class BankIdSeSignRequest {
  const BankIdSeSignRequest({
    required this.text,
    this.ssn,
    this.ipAddress,
    this.callbackUrl,
    this.pinRequired,
    this.digest,
    this.orgNumber,
    this.requestAddress,
    this.refId,
  });

  final String text;
  final String? ssn;
  final String? ipAddress;
  final String? callbackUrl;
  final bool? pinRequired;
  final String? digest;
  final String? orgNumber;
  final bool? requestAddress;
  final String? refId;

  Map<String, dynamic> toJson() => {
        'text': text,
        if (ssn != null) 'ssn': ssn,
        if (ipAddress != null) 'ipAddress': ipAddress,
        if (callbackUrl != null) 'callbackUrl': callbackUrl,
        if (pinRequired != null) 'pinRequired': pinRequired,
        if (digest != null) 'digest': digest,
        if (orgNumber != null) 'orgNumber': orgNumber,
        if (requestAddress != null) 'requestAddress': requestAddress,
        if (refId != null) 'refId': refId,
      };
}

class BankIdSePhoneSignRequest {
  const BankIdSePhoneSignRequest({
    required this.ssn,
    required this.callInitiator,
    required this.text,
    this.callbackUrl,
    this.pinRequired,
    this.digest,
    this.orgNumber,
    this.requestAddress,
    this.refId,
  });

  final String ssn;
  final String callInitiator;
  final String text;
  final String? callbackUrl;
  final bool? pinRequired;
  final String? digest;
  final String? orgNumber;
  final bool? requestAddress;
  final String? refId;

  Map<String, dynamic> toJson() => {
        'ssn': ssn,
        'callInitiator': callInitiator,
        'text': text,
        if (callbackUrl != null) 'callbackUrl': callbackUrl,
        if (pinRequired != null) 'pinRequired': pinRequired,
        if (digest != null) 'digest': digest,
        if (orgNumber != null) 'orgNumber': orgNumber,
        if (requestAddress != null) 'requestAddress': requestAddress,
        if (refId != null) 'refId': refId,
      };
}

class BankIdSeVerifyRequest {
  const BankIdSeVerifyRequest({required this.qrCode});
  final String qrCode;
  Map<String, dynamic> toJson() => {'qrCode': qrCode};
}

class BankIdSeVerifyResponse {
  const BankIdSeVerifyResponse({
    required this.ssn,
    required this.name,
    required this.givenName,
    required this.surname,
    this.age,
    this.verifiedAt,
  });

  final String ssn;
  final String name;
  final String givenName;
  final String surname;
  final int? age;
  final String? verifiedAt;

  factory BankIdSeVerifyResponse.fromJson(Map<String, dynamic> json) =>
      BankIdSeVerifyResponse(
        ssn: json['ssn'] as String,
        name: json['name'] as String,
        givenName: json['givenName'] as String,
        surname: json['surname'] as String,
        age: json['age'] as int?,
        verifiedAt: json['verifiedAt'] as String?,
      );
}

// --- Status sealed classes ---

sealed class BankIdSeStatus {
  factory BankIdSeStatus.fromJson(Map<String, dynamic> json) =>
      switch (json['status']) {
        'PENDING' => BankIdSePending.fromJson(json),
        'COMPLETED' => BankIdSeCompleted.fromJson(json),
        'FAILED' => BankIdSeFailed.fromJson(json),
        _ => throw IdkollenException(0, 'Unknown bankid-se status: ${json['status']}'),
      };
}

sealed class BankIdSePhoneStatus {
  factory BankIdSePhoneStatus.fromJson(Map<String, dynamic> json) =>
      switch (json['status']) {
        'PENDING' => BankIdSePendingPhone.fromJson(json),
        'COMPLETED' => BankIdSeCompleted.fromJson(json),
        'FAILED' => BankIdSeFailed.fromJson(json),
        _ => throw IdkollenException(0, 'Unknown bankid-se phone status: ${json['status']}'),
      };
}

final class BankIdSePending implements BankIdSeStatus {
  const BankIdSePending({
    required this.id,
    this.refId,
    this.autoStartToken,
    this.qrStartToken,
    this.qrStartSecret,
    this.hintCode,
  });

  final String id;
  final String? refId;
  final String? autoStartToken;
  final String? qrStartToken;
  final String? qrStartSecret;
  final String? hintCode;

  factory BankIdSePending.fromJson(Map<String, dynamic> json) => BankIdSePending(
        id: json['id'] as String,
        refId: json['refId'] as String?,
        autoStartToken: json['autoStartToken'] as String?,
        qrStartToken: json['qrStartToken'] as String?,
        qrStartSecret: json['qrStartSecret'] as String?,
        hintCode: json['hintCode'] as String?,
      );
}

final class BankIdSePendingPhone implements BankIdSePhoneStatus {
  const BankIdSePendingPhone({required this.id, this.refId, this.hintCode});

  final String id;
  final String? refId;
  final String? hintCode;

  factory BankIdSePendingPhone.fromJson(Map<String, dynamic> json) =>
      BankIdSePendingPhone(
        id: json['id'] as String,
        refId: json['refId'] as String?,
        hintCode: json['hintCode'] as String?,
      );
}

final class BankIdSeCompleted implements BankIdSeStatus, BankIdSePhoneStatus {
  const BankIdSeCompleted({
    required this.id,
    this.refId,
    required this.ssn,
    required this.name,
    required this.givenName,
    required this.surname,
    this.certStartDate,
    required this.ocspResponse,
    this.risk,
    this.device,
    this.stepUp,
    this.address,
    this.companySignatoryText,
    this.authenticatedAt,
    this.signedAt,
  });

  final String id;
  final String? refId;
  final String ssn;
  final String name;
  final String givenName;
  final String surname;
  final String? certStartDate;
  final String ocspResponse;
  final String? risk;
  final BankIdSeDevice? device;
  final BankIdSeStepUp? stepUp;
  final String? address;
  final String? companySignatoryText;
  final String? authenticatedAt;
  final String? signedAt;

  factory BankIdSeCompleted.fromJson(Map<String, dynamic> json) =>
      BankIdSeCompleted(
        id: json['id'] as String,
        refId: json['refId'] as String?,
        ssn: json['ssn'] as String,
        name: json['name'] as String,
        givenName: json['givenName'] as String,
        surname: json['surname'] as String,
        certStartDate: json['certStartDate'] as String?,
        ocspResponse: json['ocspResponse'] as String,
        risk: json['risk'] as String?,
        device: json['device'] == null ? null : BankIdSeDevice.fromJson(json['device'] as Map<String, dynamic>),
        stepUp: json['stepUp'] == null ? null : BankIdSeStepUp.fromJson(json['stepUp'] as Map<String, dynamic>),
        address: json['address'] as String?,
        companySignatoryText: json['companySignatoryText'] as String?,
        authenticatedAt: json['authenticatedAt'] as String?,
        signedAt: json['signedAt'] as String?,
      );
}

final class BankIdSeDevice {
  const BankIdSeDevice({this.ipAddress, this.uhi});

  final String? ipAddress;
  final String? uhi;

  factory BankIdSeDevice.fromJson(Map<String, dynamic> json) => BankIdSeDevice(
        ipAddress: json['ipAddress'] as String?,
        uhi: json['uhi'] as String?,
      );
}

final class BankIdSeStepUp {
  const BankIdSeStepUp({this.mrtd, this.face});

  final bool? mrtd;
  final bool? face;

  factory BankIdSeStepUp.fromJson(Map<String, dynamic> json) => BankIdSeStepUp(
        mrtd: json['mrtd'] as bool?,
        face: json['face'] as bool?,
      );
}

final class BankIdSeFailed implements BankIdSeStatus, BankIdSePhoneStatus {
  const BankIdSeFailed({required this.id, this.refId, required this.error});

  final String id;
  final String? refId;
  final String error;

  factory BankIdSeFailed.fromJson(Map<String, dynamic> json) => BankIdSeFailed(
        id: json['id'] as String,
        refId: json['refId'] as String?,
        error: json['error'] as String,
      );
}

// --- Endpoint ---

class BankIdSeEndpoint {
  BankIdSeEndpoint(this._transport);
  final Transport _transport;

  Future<BankIdSeStatus> auth(BankIdSeAuthRequest req) async =>
      BankIdSeStatus.fromJson(await _transport.post('/v3/bankid-se/auth', req.toJson()));

  Future<BankIdSePhoneStatus> phoneAuth(BankIdSePhoneAuthRequest req) async =>
      BankIdSePhoneStatus.fromJson(await _transport.post('/v3/bankid-se/phone/auth', req.toJson()));

  Future<BankIdSeStatus> sign(BankIdSeSignRequest req) async =>
      BankIdSeStatus.fromJson(await _transport.post('/v3/bankid-se/sign', req.toJson()));

  Future<BankIdSePhoneStatus> phoneSign(BankIdSePhoneSignRequest req) async =>
      BankIdSePhoneStatus.fromJson(await _transport.post('/v3/bankid-se/phone/sign', req.toJson()));

  Future<BankIdSeVerifyResponse> verify(BankIdSeVerifyRequest req) async =>
      BankIdSeVerifyResponse.fromJson(await _transport.post('/v3/bankid-se/verify', req.toJson()));

  Future<AgeVerificationStatus> ageVerification(AgeVerificationRequest req) async =>
      AgeVerificationStatus.fromJson(await _transport.post('/v3/bankid-se/age-verification', req.toJson()));

  Future<BankIdSeStatus> authStatus(String id) async =>
      BankIdSeStatus.fromJson(await _transport.get('/v3/bankid-se/auth/$id'));

  Future<BankIdSeStatus> signStatus(String id) async =>
      BankIdSeStatus.fromJson(await _transport.get('/v3/bankid-se/sign/$id'));

  Future<AgeVerificationStatus> ageVerificationStatus(String id) async =>
      AgeVerificationStatus.fromJson(await _transport.get('/v3/bankid-se/age-verification/$id'));

  Future<void> cancelAuth(String id) => _transport.delete('/v3/bankid-se/auth/$id');
  Future<void> cancelSign(String id) => _transport.delete('/v3/bankid-se/sign/$id');
  Future<void> cancelAgeVerification(String id) => _transport.delete('/v3/bankid-se/age-verification/$id');

  Future<BankIdSeStatus> waitForAuth(String id, {PollOptions opts = const PollOptions()}) =>
      _pollStatus(() => authStatus(id), opts);

  Future<BankIdSeStatus> waitForSign(String id, {PollOptions opts = const PollOptions()}) =>
      _pollStatus(() => signStatus(id), opts);

  Future<AgeVerificationStatus> waitForAgeVerification(String id, {PollOptions opts = const PollOptions()}) =>
      _pollAgeStatus(() => ageVerificationStatus(id), opts);

  Future<BankIdSeStatus> _pollStatus(Future<BankIdSeStatus> Function() fn, PollOptions opts) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      final status = await fn();
      if (status is! BankIdSePending) return status;
      if (stopwatch.elapsed > opts.timeout) throw WaitException(timeout: true);
      await Future<void>.delayed(opts.interval);
    }
  }

  Future<AgeVerificationStatus> _pollAgeStatus(
      Future<AgeVerificationStatus> Function() fn, PollOptions opts) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      final status = await fn();
      if (status is! AgeVerificationPending) return status;
      if (stopwatch.elapsed > opts.timeout) throw WaitException(timeout: true);
      await Future<void>.delayed(opts.interval);
    }
  }
}
