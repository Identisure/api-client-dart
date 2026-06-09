import 'age_verification.dart';
import 'exceptions.dart';
import 'poll_options.dart';
import 'transport.dart';

class MitIdAuthRequest {
  const MitIdAuthRequest({
    this.redirectUrl,
    this.referenceText,
    this.requestPhone,
    this.requestEmail,
    this.requestAddress,
    this.refId,
  });

  final String? redirectUrl;
  final String? referenceText;
  final bool? requestPhone;
  final bool? requestEmail;
  final bool? requestAddress;
  final String? refId;

  Map<String, dynamic> toJson() => {
        if (redirectUrl != null) 'redirectUrl': redirectUrl,
        if (referenceText != null) 'referenceText': referenceText,
        if (requestPhone != null) 'requestPhone': requestPhone,
        if (requestEmail != null) 'requestEmail': requestEmail,
        if (requestAddress != null) 'requestAddress': requestAddress,
        if (refId != null) 'refId': refId,
      };
}

class MitIdBackchannelAuthRequest {
  const MitIdBackchannelAuthRequest({
    required this.ssn,
    required this.bindingMessage,
    this.callbackUrl,
    this.refId,
  });

  final String ssn;
  final String bindingMessage;
  final String? callbackUrl;
  final String? refId;

  Map<String, dynamic> toJson() => {
        'ssn': ssn,
        'bindingMessage': bindingMessage,
        if (callbackUrl != null) 'callbackUrl': callbackUrl,
        if (refId != null) 'refId': refId,
      };
}

class MitIdSignRequest {
  const MitIdSignRequest({
    required this.text,
    this.redirectUrl,
    this.refId,
  });

  final String text;
  final String? redirectUrl;
  final String? refId;

  Map<String, dynamic> toJson() => {
        'text': text,
        if (redirectUrl != null) 'redirectUrl': redirectUrl,
        if (refId != null) 'refId': refId,
      };
}

class MitIdSignResult {
  const MitIdSignResult({required this.checksum});
  final String checksum;
  factory MitIdSignResult.fromJson(Map<String, dynamic> json) =>
      MitIdSignResult(checksum: json['checksum'] as String);
}

sealed class MitIdStatus {
  factory MitIdStatus.fromJson(Map<String, dynamic> json) => switch (json['status']) {
        'PENDING' => MitIdPending.fromJson(json),
        'COMPLETED' => MitIdCompleted.fromJson(json),
        'FAILED' => MitIdFailed.fromJson(json),
        _ => throw FormatException('Unknown mitid status: ${json['status']}'),
      };
}

final class MitIdPending implements MitIdStatus {
  const MitIdPending({required this.id, this.refId, this.url, this.bindingMessage});
  final String id;
  final String? refId;
  final String? url;
  final String? bindingMessage;
  factory MitIdPending.fromJson(Map<String, dynamic> json) => MitIdPending(
        id: json['id'] as String,
        refId: json['refId'] as String?,
        url: json['url'] as String?,
        bindingMessage: json['bindingMessage'] as String?,
      );
}

final class MitIdCompleted implements MitIdStatus {
  const MitIdCompleted({
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
    this.signResult,
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
  final MitIdSignResult? signResult;

  factory MitIdCompleted.fromJson(Map<String, dynamic> json) => MitIdCompleted(
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
        signResult: json['signResult'] == null
            ? null
            : MitIdSignResult.fromJson(json['signResult'] as Map<String, dynamic>),
      );
}

final class MitIdFailed implements MitIdStatus {
  const MitIdFailed({required this.id, this.refId, required this.error});
  final String id;
  final String? refId;
  final String error;
  factory MitIdFailed.fromJson(Map<String, dynamic> json) => MitIdFailed(
        id: json['id'] as String,
        refId: json['refId'] as String?,
        error: json['error'] as String,
      );
}

class MitIdEndpoint {
  MitIdEndpoint(this._transport);
  final Transport _transport;

  Future<MitIdStatus> auth(MitIdAuthRequest req) async =>
      MitIdStatus.fromJson(await _transport.post('/v3/mitid/auth', req.toJson()));
  Future<MitIdStatus> backchannelAuth(MitIdBackchannelAuthRequest req) async =>
      MitIdStatus.fromJson(await _transport.post('/v3/mitid/backchannel/auth', req.toJson()));
  Future<MitIdStatus> sign(MitIdSignRequest req) async =>
      MitIdStatus.fromJson(await _transport.post('/v3/mitid/sign', req.toJson()));
  Future<MitIdStatus> authStatus(String id) async =>
      MitIdStatus.fromJson(await _transport.get('/v3/mitid/auth/$id'));
  Future<MitIdStatus> signStatus(String id) async =>
      MitIdStatus.fromJson(await _transport.get('/v3/mitid/sign/$id'));
  Future<void> cancelAuth(String id) => _transport.delete('/v3/mitid/auth/$id');
  Future<void> cancelSign(String id) => _transport.delete('/v3/mitid/sign/$id');
  Future<void> cancelAgeVerification(String id) => _transport.delete('/v3/mitid/age-verification/$id');

  Future<MitIdStatus> waitForAuth(String id, {PollOptions opts = const PollOptions()}) =>
      _poll(() => authStatus(id), opts);
  Future<MitIdStatus> waitForSign(String id, {PollOptions opts = const PollOptions()}) =>
      _poll(() => signStatus(id), opts);

  Future<AgeVerificationStatus> ageVerification(AgeVerificationRequest req) async =>
      AgeVerificationStatus.fromJson(await _transport.post('/v3/mitid/age-verification', req.toJson()));

  Future<AgeVerificationStatus> ageVerificationStatus(String id) async =>
      AgeVerificationStatus.fromJson(await _transport.get('/v3/mitid/age-verification/$id'));

  Future<AgeVerificationStatus> waitForAgeVerification(String id, {PollOptions opts = const PollOptions()}) =>
      _pollAge(() => ageVerificationStatus(id), opts);

  Future<MitIdStatus> _poll(Future<MitIdStatus> Function() fn, PollOptions opts) async {
    final deadline = DateTime.now().add(opts.timeout);
    while (true) {
      final status = await fn();
      if (status is! MitIdPending) return status;
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
