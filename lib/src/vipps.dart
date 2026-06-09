import 'exceptions.dart';
import 'poll_options.dart';
import 'transport.dart';

class VippsAuthRequest {
  const VippsAuthRequest({
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

class VippsBackchannelAuthRequest {
  const VippsBackchannelAuthRequest({
    required this.phone,
    this.requestSsn,
    this.requestEmail,
    this.requestAddress,
    this.callbackUrl,
    this.refId,
  });

  final String phone;
  final bool? requestSsn;
  final bool? requestEmail;
  final bool? requestAddress;
  final String? callbackUrl;
  final String? refId;

  Map<String, dynamic> toJson() => {
        'phone': phone,
        if (requestSsn != null) 'requestSsn': requestSsn,
        if (requestEmail != null) 'requestEmail': requestEmail,
        if (requestAddress != null) 'requestAddress': requestAddress,
        if (callbackUrl != null) 'callbackUrl': callbackUrl,
        if (refId != null) 'refId': refId,
      };
}

sealed class VippsStatus {
  factory VippsStatus.fromJson(Map<String, dynamic> json) => switch (json['status']) {
        'PENDING' => VippsPending.fromJson(json),
        'COMPLETED' => VippsCompleted.fromJson(json),
        'FAILED' => VippsFailed.fromJson(json),
        _ => throw FormatException('Unknown vipps status: ${json['status']}'),
      };
}

final class VippsPending implements VippsStatus {
  const VippsPending({required this.id, this.refId, this.url});
  final String id;
  final String? refId;
  final String? url;
  factory VippsPending.fromJson(Map<String, dynamic> json) => VippsPending(
        id: json['id'] as String,
        refId: json['refId'] as String?,
        url: json['url'] as String?,
      );
}

final class VippsCompleted implements VippsStatus {
  const VippsCompleted({
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

  factory VippsCompleted.fromJson(Map<String, dynamic> json) => VippsCompleted(
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

final class VippsFailed implements VippsStatus {
  const VippsFailed({required this.id, this.refId, required this.error});
  final String id;
  final String? refId;
  final String error;
  factory VippsFailed.fromJson(Map<String, dynamic> json) => VippsFailed(
        id: json['id'] as String,
        refId: json['refId'] as String?,
        error: json['error'] as String,
      );
}

class VippsEndpoint {
  VippsEndpoint(this._transport);
  final Transport _transport;

  Future<VippsStatus> auth(VippsAuthRequest req) async =>
      VippsStatus.fromJson(await _transport.post('/v3/vipps/auth', req.toJson()));
  Future<VippsStatus> backchannelAuth(VippsBackchannelAuthRequest req) async =>
      VippsStatus.fromJson(await _transport.post('/v3/vipps/backchannel/auth', req.toJson()));
  Future<VippsStatus> authStatus(String id) async =>
      VippsStatus.fromJson(await _transport.get('/v3/vipps/auth/$id'));
  Future<void> cancelAuth(String id) => _transport.delete('/v3/vipps/auth/$id');

  Future<VippsStatus> waitForAuth(String id, {PollOptions opts = const PollOptions()}) =>
      _poll(() => authStatus(id), opts);

  Future<VippsStatus> _poll(Future<VippsStatus> Function() fn, PollOptions opts) async {
    final deadline = DateTime.now().add(opts.timeout);
    while (true) {
      final status = await fn();
      if (status is! VippsPending) return status;
      if (DateTime.now().isAfter(deadline)) throw WaitException(timeout: true);
      await Future<void>.delayed(opts.interval);
    }
  }
}
