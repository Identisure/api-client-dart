import 'exceptions.dart';
import 'poll_options.dart';
import 'transport.dart';

class BankIdNoAuthRequest {
  const BankIdNoAuthRequest({
    this.redirectUrl,
    this.requestSsn,
    this.requestPhone,
    this.requestEmail,
    this.requestAddress,
    this.refId,
    this.appCallbackUri,
  });

  final String? redirectUrl;
  final bool? requestSsn;
  final bool? requestPhone;
  final bool? requestEmail;
  final bool? requestAddress;
  final String? refId;
  final String? appCallbackUri;

  Map<String, dynamic> toJson() => {
        if (redirectUrl != null) 'redirectUrl': redirectUrl,
        if (requestSsn != null) 'requestSsn': requestSsn,
        if (requestPhone != null) 'requestPhone': requestPhone,
        if (requestEmail != null) 'requestEmail': requestEmail,
        if (requestAddress != null) 'requestAddress': requestAddress,
        if (refId != null) 'refId': refId,
        if (appCallbackUri != null) 'appCallbackUri': appCallbackUri,
      };
}

class BankIdNoBackchannelAuthRequest {
  const BankIdNoBackchannelAuthRequest({required this.ssn, this.callbackUrl, this.refId});
  final String ssn;
  final String? callbackUrl;
  final String? refId;
  Map<String, dynamic> toJson() => {
        'ssn': ssn,
        if (callbackUrl != null) 'callbackUrl': callbackUrl,
        if (refId != null) 'refId': refId,
      };
}

class BankIdNoSignRequest {
  const BankIdNoSignRequest({
    this.redirectUrl,
    this.text,
    this.documents,
    this.requestSsn,
    this.requestPhone,
    this.requestEmail,
    this.requestAddress,
    this.refId,
  });

  final String? redirectUrl;
  final String? text;
  final List<String>? documents;
  final bool? requestSsn;
  final bool? requestPhone;
  final bool? requestEmail;
  final bool? requestAddress;
  final String? refId;

  Map<String, dynamic> toJson() => {
        if (redirectUrl != null) 'redirectUrl': redirectUrl,
        if (text != null) 'text': text,
        if (documents != null) 'documents': documents,
        if (requestSsn != null) 'requestSsn': requestSsn,
        if (requestPhone != null) 'requestPhone': requestPhone,
        if (requestEmail != null) 'requestEmail': requestEmail,
        if (requestAddress != null) 'requestAddress': requestAddress,
        if (refId != null) 'refId': refId,
      };
}

class BankIdNoSignResult {
  const BankIdNoSignResult({required this.endUser, required this.merchant, required this.hash});
  final String endUser;
  final String merchant;
  final String hash;
  factory BankIdNoSignResult.fromJson(Map<String, dynamic> json) => BankIdNoSignResult(
        endUser: json['endUser'] as String,
        merchant: json['merchant'] as String,
        hash: json['hash'] as String,
      );
}

class BankIdNoSignedDocument {
  const BankIdNoSignedDocument({required this.id, required this.hash});
  final String id;
  final String hash;
  factory BankIdNoSignedDocument.fromJson(Map<String, dynamic> json) => BankIdNoSignedDocument(
        id: json['id'] as String,
        hash: json['hash'] as String,
      );
}

sealed class BankIdNoStatus {
  factory BankIdNoStatus.fromJson(Map<String, dynamic> json) => switch (json['status']) {
        'PENDING' => BankIdNoPending.fromJson(json),
        'COMPLETED' => BankIdNoCompleted.fromJson(json),
        'FAILED' => BankIdNoFailed.fromJson(json),
        _ => throw FormatException('Unknown bankid-no status: ${json['status']}'),
      };
}

final class BankIdNoPending implements BankIdNoStatus {
  const BankIdNoPending({required this.id, this.refId, this.url, this.bindingMessage});
  final String id;
  final String? refId;
  final String? url;
  final String? bindingMessage;
  factory BankIdNoPending.fromJson(Map<String, dynamic> json) => BankIdNoPending(
        id: json['id'] as String,
        refId: json['refId'] as String?,
        url: json['url'] as String?,
        bindingMessage: json['bindingMessage'] as String?,
      );
}

final class BankIdNoCompleted implements BankIdNoStatus {
  const BankIdNoCompleted({
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
    this.signedDocuments,
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
  final BankIdNoSignResult? signResult;
  final List<BankIdNoSignedDocument>? signedDocuments;

  factory BankIdNoCompleted.fromJson(Map<String, dynamic> json) => BankIdNoCompleted(
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
            : BankIdNoSignResult.fromJson(json['signResult'] as Map<String, dynamic>),
        signedDocuments: (json['signedDocuments'] as List<dynamic>?)
            ?.map((e) => BankIdNoSignedDocument.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

final class BankIdNoFailed implements BankIdNoStatus {
  const BankIdNoFailed({required this.id, this.refId, required this.error});
  final String id;
  final String? refId;
  final String error;
  factory BankIdNoFailed.fromJson(Map<String, dynamic> json) => BankIdNoFailed(
        id: json['id'] as String,
        refId: json['refId'] as String?,
        error: json['error'] as String,
      );
}

class BankIdNoEndpoint {
  BankIdNoEndpoint(this._transport);
  final Transport _transport;

  Future<BankIdNoStatus> auth(BankIdNoAuthRequest req) async =>
      BankIdNoStatus.fromJson(await _transport.post('/v3/bankid-no/auth', req.toJson()));
  Future<BankIdNoStatus> backchannelAuth(BankIdNoBackchannelAuthRequest req) async =>
      BankIdNoStatus.fromJson(await _transport.post('/v3/bankid-no/backchannel/auth', req.toJson()));
  Future<BankIdNoStatus> sign(BankIdNoSignRequest req) async =>
      BankIdNoStatus.fromJson(await _transport.post('/v3/bankid-no/sign', req.toJson()));
  Future<BankIdNoStatus> authStatus(String id) async =>
      BankIdNoStatus.fromJson(await _transport.get('/v3/bankid-no/auth/$id'));
  Future<BankIdNoStatus> signStatus(String id) async =>
      BankIdNoStatus.fromJson(await _transport.get('/v3/bankid-no/sign/$id'));
  Future<void> cancelAuth(String id) => _transport.delete('/v3/bankid-no/auth/$id');
  Future<void> cancelSign(String id) => _transport.delete('/v3/bankid-no/sign/$id');

  Future<BankIdNoStatus> waitForAuth(String id, {PollOptions opts = const PollOptions()}) =>
      _poll(() => authStatus(id), opts);
  Future<BankIdNoStatus> waitForSign(String id, {PollOptions opts = const PollOptions()}) =>
      _poll(() => signStatus(id), opts);

  Future<BankIdNoStatus> _poll(Future<BankIdNoStatus> Function() fn, PollOptions opts) async {
    final deadline = DateTime.now().add(opts.timeout);
    while (true) {
      final status = await fn();
      if (status is! BankIdNoPending) return status;
      if (DateTime.now().isAfter(deadline)) throw WaitException(timeout: true);
      await Future<void>.delayed(opts.interval);
    }
  }
}
