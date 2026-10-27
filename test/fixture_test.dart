import 'dart:convert';
import 'dart:io';

import 'package:identisure_client/identisure_client.dart';
import 'package:test/test.dart';

import 'mock_client.dart';

const _fastPoll = PollOptions(interval: Duration(milliseconds: 1));
final _authHeader = 'Basic ${base64Encode(utf8.encode('cid:sec'))}';

String _raw(String path) => File('fixtures/$path').readAsStringSync();
Map<String, dynamic> _fixture(String path) =>
    jsonDecode(_raw(path)) as Map<String, dynamic>;

void main() {
  late MockClient mock;
  late IdentisureClient client;

  setUp(() {
    mock = MockClient();
    client = IdentisureClientBuilder('cid', 'sec')
        .baseUrl('https://x.test')
        .httpClient(mock)
        .build();
  });

  /// Queues start (201), one pending poll and the terminal poll. Returns the session id.
  String enqueueFlow(String pending, String terminal) {
    mock.enqueue(201, _raw(pending));
    mock.enqueue(200, _raw(pending));
    mock.enqueue(200, _raw(terminal));
    return _fixture(pending)['id'] as String;
  }

  /// Queues start (201) and the terminal poll. Returns the session id.
  String enqueueTerminal(String pending, String terminal) {
    mock.enqueue(201, _raw(pending));
    mock.enqueue(200, _raw(terminal));
    return _fixture(pending)['id'] as String;
  }

  void expectRequests(List<(String, String)> expected) {
    expect(mock.requests.map((r) => (r.method, r.url.path)).toList(), expected);
    for (final request in mock.requests) {
      expect(request.headers['Authorization'], _authHeader);
    }
  }

  List<(String, String)> authFlow(String segment, String id) => [
        ('POST', '/v3/$segment/auth'),
        ('GET', '/v3/$segment/auth/$id'),
        ('GET', '/v3/$segment/auth/$id')
      ];

  List<(String, String)> signFlow(String segment, String id) => [
        ('POST', '/v3/$segment/sign'),
        ('GET', '/v3/$segment/sign/$id'),
        ('GET', '/v3/$segment/sign/$id')
      ];

  void expectPerson(Map<String, dynamic> f,
      {required String id,
      required String? refId,
      required String? ssn,
      required String name,
      required String givenName,
      required String surname}) {
    expect(id, f['id']);
    expect(refId, f['refId']);
    expect(ssn, f['ssn']);
    expect(name, f['name']);
    expect(givenName, f['givenName']);
    expect(surname, f['surname']);
  }

  void expectContact(Map<String, dynamic> f,
      {required String? phone,
      required String? email,
      required String? address,
      required String? birthDate,
      required String? pid,
      required String? bankId}) {
    expect(phone, f['phone']);
    expect(email, f['email']);
    expect(address, f['address']);
    expect(birthDate, f['birthDate']);
    expect(pid, f['pid']);
    expect(bankId, f['bankId']);
  }

  void expectBankIdSeCompleted(BankIdSeCompleted done, String path) {
    final f = _fixture(path);
    expectPerson(f,
        id: done.id,
        refId: done.refId,
        ssn: done.ssn,
        name: done.name,
        givenName: done.givenName,
        surname: done.surname);
    expect(done.certStartDate, f['certStartDate']);
    expect(done.ocspResponse, f['ocspResponse']);
    expect(done.risk, f['risk']);
    expect(done.address, f['address']);
    expect(done.authenticatedAt, f['authenticatedAt']);
    expect(done.signedAt, f['signedAt']);
    expect(done.device?.ipAddress, f['device']['ipAddress']);
    expect(done.device?.uhi, f['device']['uhi']);
    expect(done.stepUp?.mrtd, f['stepUp']['mrtd']);
    expect(done.stepUp?.face, f['stepUp']['face']);
  }

  void expectFrejaCompleted(FrejaCompleted done, String path) {
    final f = _fixture(path);
    expectPerson(f,
        id: done.id,
        refId: done.refId,
        ssn: done.ssn,
        name: done.name,
        givenName: done.givenName,
        surname: done.surname);
    expect(done.country, f['country']);
    expect(done.address, f['address']);
    expect(done.authenticatedAt, f['authenticatedAt']);
    expect(done.signedAt, f['signedAt']);
  }

  void expectFailed(String id, String error, String path) {
    final f = _fixture(path);
    expect(id, f['id']);
    expect(error, f['error']);
    expect(error, 'CANCELLED');
  }

  group('auth', () {
    test('bankid-se', () async {
      final id = enqueueFlow(
          'bankid_se/auth_pending.json', 'bankid_se/auth_completed.json');

      final pending = await client.bankIdSe.auth(const BankIdSeAuthRequest());
      expect(pending, isA<BankIdSePending>());
      final p = _fixture('bankid_se/auth_pending.json');
      expect((pending as BankIdSePending).id, id);
      expect(pending.autoStartToken, p['autoStartToken']);
      expect(pending.qrStartToken, p['qrStartToken']);
      expect(pending.qrStartSecret, p['qrStartSecret']);
      expect(pending.hintCode, p['hintCode']);

      final result = await client.bankIdSe.waitForAuth(id, opts: _fastPoll);
      expect(result, isA<BankIdSeCompleted>());
      expectBankIdSeCompleted(
          result as BankIdSeCompleted, 'bankid_se/auth_completed.json');
      expectRequests(authFlow('bankid-se', id));
    });

    test('bankid-no', () async {
      final id = enqueueFlow(
          'bankid_no/auth_pending.json', 'bankid_no/auth_completed.json');

      final pending = await client.bankIdNo.auth(const BankIdNoAuthRequest());
      expect(pending, isA<BankIdNoPending>());
      final p = _fixture('bankid_no/auth_pending.json');
      expect((pending as BankIdNoPending).id, id);
      expect(pending.url, p['url']);
      expect(pending.bindingMessage, p['bindingMessage']);

      final result = await client.bankIdNo.waitForAuth(id, opts: _fastPoll);
      expect(result, isA<BankIdNoCompleted>());
      final done = result as BankIdNoCompleted;
      final f = _fixture('bankid_no/auth_completed.json');
      expectPerson(f,
          id: done.id,
          refId: done.refId,
          ssn: done.ssn,
          name: done.name,
          givenName: done.givenName,
          surname: done.surname);
      expectContact(f,
          phone: done.phone,
          email: done.email,
          address: done.address,
          birthDate: done.birthDate,
          pid: done.pid,
          bankId: done.bankId);
      expect(done.authenticatedAt, f['authenticatedAt']);
      expectRequests(authFlow('bankid-no', id));
    });

    test('freja', () async {
      final id =
          enqueueFlow('freja/auth_pending.json', 'freja/auth_completed.json');

      final pending = await client.freja.auth(const FrejaAuthRequest());
      expect(pending, isA<FrejaPending>());
      final p = _fixture('freja/auth_pending.json');
      expect((pending as FrejaPending).id, id);
      expect(pending.autoStartToken, p['autoStartToken']);
      expect(pending.qrData, p['qrData']);

      final result = await client.freja.waitForAuth(id, opts: _fastPoll);
      expect(result, isA<FrejaCompleted>());
      expectFrejaCompleted(
          result as FrejaCompleted, 'freja/auth_completed.json');
      expectRequests(authFlow('freja', id));
    });

    test('mitid', () async {
      final id =
          enqueueFlow('mitid/auth_pending.json', 'mitid/auth_completed.json');

      final pending = await client.mitId.auth(const MitIdAuthRequest());
      expect(pending, isA<MitIdPending>());
      expect((pending as MitIdPending).id, id);
      expect(pending.url, _fixture('mitid/auth_pending.json')['url']);

      final result = await client.mitId.waitForAuth(id, opts: _fastPoll);
      expect(result, isA<MitIdCompleted>());
      final done = result as MitIdCompleted;
      final f = _fixture('mitid/auth_completed.json');
      expectPerson(f,
          id: done.id,
          refId: done.refId,
          ssn: done.ssn,
          name: done.name,
          givenName: done.givenName,
          surname: done.surname);
      expectContact(f,
          phone: done.phone,
          email: done.email,
          address: done.address,
          birthDate: done.birthDate,
          pid: done.pid,
          bankId: done.bankId);
      expect(done.authenticatedAt, f['authenticatedAt']);
      expectRequests(authFlow('mitid', id));
    });

    test('ftn', () async {
      final id =
          enqueueFlow('ftn/auth_pending.json', 'ftn/auth_completed.json');

      final pending = await client.ftn.auth(const FtnAuthRequest());
      expect(pending, isA<FtnPending>());
      expect((pending as FtnPending).id, id);
      expect(pending.url, _fixture('ftn/auth_pending.json')['url']);

      final result = await client.ftn.waitForAuth(id, opts: _fastPoll);
      expect(result, isA<FtnCompleted>());
      final done = result as FtnCompleted;
      final f = _fixture('ftn/auth_completed.json');
      expectPerson(f,
          id: done.id,
          refId: done.refId,
          ssn: done.ssn,
          name: done.name,
          givenName: done.givenName,
          surname: done.surname);
      expectContact(f,
          phone: done.phone,
          email: done.email,
          address: done.address,
          birthDate: done.birthDate,
          pid: done.pid,
          bankId: done.bankId);
      expect(done.bankName, f['bankName']);
      expect(done.authenticatedAt, f['authenticatedAt']);
      expectRequests(authFlow('ftn', id));
    });

    test('vipps', () async {
      final id =
          enqueueFlow('vipps/auth_pending.json', 'vipps/auth_completed.json');

      final pending = await client.vipps.auth(const VippsAuthRequest());
      expect(pending, isA<VippsPending>());
      expect((pending as VippsPending).id, id);
      expect(pending.url, _fixture('vipps/auth_pending.json')['url']);

      final result = await client.vipps.waitForAuth(id, opts: _fastPoll);
      expect(result, isA<VippsCompleted>());
      final done = result as VippsCompleted;
      final f = _fixture('vipps/auth_completed.json');
      expectPerson(f,
          id: done.id,
          refId: done.refId,
          ssn: done.ssn,
          name: done.name,
          givenName: done.givenName,
          surname: done.surname);
      expectContact(f,
          phone: done.phone,
          email: done.email,
          address: done.address,
          birthDate: done.birthDate,
          pid: done.pid,
          bankId: done.bankId);
      expect(done.authenticatedAt, f['authenticatedAt']);
      expectRequests(authFlow('vipps', id));
    });
  });

  group('failed and unknown', () {
    test('bankid-se', () async {
      var id = enqueueTerminal(
          'bankid_se/auth_pending.json', 'bankid_se/auth_failed.json');
      await client.bankIdSe.auth(const BankIdSeAuthRequest());
      final failed = await client.bankIdSe.waitForAuth(id, opts: _fastPoll);
      expect(failed, isA<BankIdSeFailed>());
      expectFailed((failed as BankIdSeFailed).id, failed.error,
          'bankid_se/auth_failed.json');

      id = enqueueTerminal(
          'bankid_se/auth_pending.json', 'bankid_se/auth_unknown.json');
      await client.bankIdSe.auth(const BankIdSeAuthRequest());
      final unknown = await client.bankIdSe.waitForAuth(id, opts: _fastPoll);
      expect(unknown, isA<BankIdSeUnknown>());
      expect((unknown as BankIdSeUnknown).status, 'SOMETHING_NEW');
    });

    test('bankid-no', () async {
      var id = enqueueTerminal(
          'bankid_no/auth_pending.json', 'bankid_no/auth_failed.json');
      await client.bankIdNo.auth(const BankIdNoAuthRequest());
      final failed = await client.bankIdNo.waitForAuth(id, opts: _fastPoll);
      expect(failed, isA<BankIdNoFailed>());
      expectFailed((failed as BankIdNoFailed).id, failed.error,
          'bankid_no/auth_failed.json');

      id = enqueueTerminal(
          'bankid_no/auth_pending.json', 'bankid_no/auth_unknown.json');
      await client.bankIdNo.auth(const BankIdNoAuthRequest());
      final unknown = await client.bankIdNo.waitForAuth(id, opts: _fastPoll);
      expect(unknown, isA<BankIdNoUnknown>());
      expect((unknown as BankIdNoUnknown).status, 'SOMETHING_NEW');
    });

    test('freja', () async {
      var id =
          enqueueTerminal('freja/auth_pending.json', 'freja/auth_failed.json');
      await client.freja.auth(const FrejaAuthRequest());
      final failed = await client.freja.waitForAuth(id, opts: _fastPoll);
      expect(failed, isA<FrejaFailed>());
      expectFailed(
          (failed as FrejaFailed).id, failed.error, 'freja/auth_failed.json');

      id =
          enqueueTerminal('freja/auth_pending.json', 'freja/auth_unknown.json');
      await client.freja.auth(const FrejaAuthRequest());
      final unknown = await client.freja.waitForAuth(id, opts: _fastPoll);
      expect(unknown, isA<FrejaUnknown>());
      expect((unknown as FrejaUnknown).status, 'SOMETHING_NEW');
    });

    test('mitid', () async {
      var id =
          enqueueTerminal('mitid/auth_pending.json', 'mitid/auth_failed.json');
      await client.mitId.auth(const MitIdAuthRequest());
      final failed = await client.mitId.waitForAuth(id, opts: _fastPoll);
      expect(failed, isA<MitIdFailed>());
      expectFailed(
          (failed as MitIdFailed).id, failed.error, 'mitid/auth_failed.json');

      id =
          enqueueTerminal('mitid/auth_pending.json', 'mitid/auth_unknown.json');
      await client.mitId.auth(const MitIdAuthRequest());
      final unknown = await client.mitId.waitForAuth(id, opts: _fastPoll);
      expect(unknown, isA<MitIdUnknown>());
      expect((unknown as MitIdUnknown).status, 'SOMETHING_NEW');
    });

    test('ftn', () async {
      var id = enqueueTerminal('ftn/auth_pending.json', 'ftn/auth_failed.json');
      await client.ftn.auth(const FtnAuthRequest());
      final failed = await client.ftn.waitForAuth(id, opts: _fastPoll);
      expect(failed, isA<FtnFailed>());
      expectFailed(
          (failed as FtnFailed).id, failed.error, 'ftn/auth_failed.json');

      id = enqueueTerminal('ftn/auth_pending.json', 'ftn/auth_unknown.json');
      await client.ftn.auth(const FtnAuthRequest());
      final unknown = await client.ftn.waitForAuth(id, opts: _fastPoll);
      expect(unknown, isA<FtnUnknown>());
      expect((unknown as FtnUnknown).status, 'SOMETHING_NEW');
    });

    test('vipps', () async {
      var id =
          enqueueTerminal('vipps/auth_pending.json', 'vipps/auth_failed.json');
      await client.vipps.auth(const VippsAuthRequest());
      final failed = await client.vipps.waitForAuth(id, opts: _fastPoll);
      expect(failed, isA<VippsFailed>());
      expectFailed(
          (failed as VippsFailed).id, failed.error, 'vipps/auth_failed.json');

      id =
          enqueueTerminal('vipps/auth_pending.json', 'vipps/auth_unknown.json');
      await client.vipps.auth(const VippsAuthRequest());
      final unknown = await client.vipps.waitForAuth(id, opts: _fastPoll);
      expect(unknown, isA<VippsUnknown>());
      expect((unknown as VippsUnknown).status, 'SOMETHING_NEW');
    });
  });

  group('sign', () {
    test('bankid-se', () async {
      final id = enqueueFlow(
          'bankid_se/auth_pending.json', 'bankid_se/sign_completed.json');

      expect(
          await client.bankIdSe
              .sign(const BankIdSeSignRequest(text: 'Sign this')),
          isA<BankIdSePending>());
      final result = await client.bankIdSe.waitForSign(id, opts: _fastPoll);
      expect(result, isA<BankIdSeCompleted>());
      expectBankIdSeCompleted(
          result as BankIdSeCompleted, 'bankid_se/sign_completed.json');
      expectRequests(signFlow('bankid-se', id));
    });

    test('bankid-no', () async {
      final id = enqueueFlow(
          'bankid_no/auth_pending.json', 'bankid_no/sign_completed.json');

      expect(
          await client.bankIdNo
              .sign(const BankIdNoSignRequest(text: 'Sign this')),
          isA<BankIdNoPending>());
      final result = await client.bankIdNo.waitForSign(id, opts: _fastPoll);
      expect(result, isA<BankIdNoCompleted>());
      final done = result as BankIdNoCompleted;
      final f = _fixture('bankid_no/sign_completed.json');
      expectPerson(f,
          id: done.id,
          refId: done.refId,
          ssn: done.ssn,
          name: done.name,
          givenName: done.givenName,
          surname: done.surname);
      expect(done.signedAt, f['signedAt']);
      expect(done.signResult?.endUser, f['signResult']['endUser']);
      expect(done.signResult?.merchant, f['signResult']['merchant']);
      expect(done.signResult?.hash, f['signResult']['hash']);
      final docs = f['signedDocuments'] as List<dynamic>;
      expect(done.signedDocuments, hasLength(docs.length));
      expect(done.signedDocuments!.first.id, docs.first['id']);
      expect(done.signedDocuments!.first.hash, docs.first['hash']);
      expectRequests(signFlow('bankid-no', id));
    });

    test('freja', () async {
      final id =
          enqueueFlow('freja/auth_pending.json', 'freja/sign_completed.json');

      expect(await client.freja.sign(const FrejaSignRequest(text: 'Sign this')),
          isA<FrejaPending>());
      final result = await client.freja.waitForSign(id, opts: _fastPoll);
      expect(result, isA<FrejaCompleted>());
      expectFrejaCompleted(
          result as FrejaCompleted, 'freja/sign_completed.json');
      expectRequests(signFlow('freja', id));
    });

    test('mitid', () async {
      final id =
          enqueueFlow('mitid/auth_pending.json', 'mitid/sign_completed.json');

      expect(await client.mitId.sign(const MitIdSignRequest(text: 'Sign this')),
          isA<MitIdPending>());
      final result = await client.mitId.waitForSign(id, opts: _fastPoll);
      expect(result, isA<MitIdCompleted>());
      final done = result as MitIdCompleted;
      final f = _fixture('mitid/sign_completed.json');
      expectPerson(f,
          id: done.id,
          refId: done.refId,
          ssn: done.ssn,
          name: done.name,
          givenName: done.givenName,
          surname: done.surname);
      expect(done.signedAt, f['signedAt']);
      expect(done.signResult?.checksum, f['signResult']['checksum']);
      expectRequests(signFlow('mitid', id));
    });
  });

  test('bankid-se phone auth', () async {
    final id = _fixture('bankid_se/phone_auth_pending.json')['id'] as String;
    mock.enqueue(201, _raw('bankid_se/phone_auth_pending.json'));
    mock.enqueue(200, _raw('bankid_se/auth_completed.json'));

    final pending = await client.bankIdSe.phoneAuth(
        const BankIdSePhoneAuthRequest(
            ssn: '199001011239', callInitiator: 'USER'));
    expect(pending, isA<BankIdSePendingPhone>());
    expect((pending as BankIdSePendingPhone).id, id);
    expect(pending.hintCode, isNull);

    final result = await client.bankIdSe.waitForAuth(id, opts: _fastPoll);
    expect(result, isA<BankIdSeCompleted>());
    expectBankIdSeCompleted(
        result as BankIdSeCompleted, 'bankid_se/auth_completed.json');
    expectRequests([
      ('POST', '/v3/bankid-se/phone/auth'),
      ('GET', '/v3/bankid-se/auth/$id')
    ]);
  });

  test('bankid-se verify', () async {
    mock.enqueue(200, _raw('bankid_se/verify.json'));

    final result = await client.bankIdSe
        .verify(const BankIdSeVerifyRequest(qrCode: 'bankidqr.1.2.3'));

    final f = _fixture('bankid_se/verify.json');
    expect(result.ssn, f['ssn']);
    expect(result.name, f['name']);
    expect(result.givenName, f['givenName']);
    expect(result.surname, f['surname']);
    expect(result.age, f['age']);
    expect(result.verifiedAt, f['verifiedAt']);
    expectRequests([('POST', '/v3/bankid-se/verify')]);
  });

  group('age verification', () {
    test('completes', () async {
      final id = enqueueFlow(
          'age_verification/pending.json', 'age_verification/completed.json');

      final pending = await client.bankIdSe
          .ageVerification(const AgeVerificationRequest(minAge: 18));
      expect(pending, isA<AgeVerificationPending>());
      final p = _fixture('age_verification/pending.json');
      expect((pending as AgeVerificationPending).id, id);
      expect(pending.url, p['url']);
      expect(pending.minAge, p['minAge']);
      expect(pending.maxAge, p['maxAge']);

      final result =
          await client.bankIdSe.waitForAgeVerification(id, opts: _fastPoll);
      expect(result, isA<AgeVerificationCompleted>());
      expect((result as AgeVerificationCompleted).id, id);
      expect(result.ageVerified,
          _fixture('age_verification/completed.json')['ageVerified']);
      expectRequests([
        ('POST', '/v3/bankid-se/age-verification'),
        ('GET', '/v3/bankid-se/age-verification/$id'),
        ('GET', '/v3/bankid-se/age-verification/$id'),
      ]);
    });

    test('fails', () async {
      final id = enqueueTerminal(
          'age_verification/pending.json', 'age_verification/failed.json');
      await client.bankIdSe
          .ageVerification(const AgeVerificationRequest(minAge: 18));

      final result =
          await client.bankIdSe.waitForAgeVerification(id, opts: _fastPoll);
      expect(result, isA<AgeVerificationFailed>());
      final f = _fixture('age_verification/failed.json');
      expect((result as AgeVerificationFailed).id, f['id']);
      expect(result.error, f['error']);
    });

    test('unknown status', () async {
      final id = enqueueTerminal(
          'age_verification/pending.json', 'age_verification/unknown.json');
      await client.bankIdSe
          .ageVerification(const AgeVerificationRequest(minAge: 18));

      final result =
          await client.bankIdSe.waitForAgeVerification(id, opts: _fastPoll);
      expect(result, isA<AgeVerificationUnknown>());
      expect((result as AgeVerificationUnknown).status, 'SOMETHING_NEW');
    });
  });

  test('document upload', () async {
    mock.enqueue(201, _raw('document/upload.json'));

    final result =
        await client.document.upload(utf8.encode('%PDF-1.7'), 'contract.pdf');

    final f = _fixture('document/upload.json');
    expect(result.id, f['id']);
    expect(result.hash, f['hash']);
    expectRequests([('POST', '/v3/document')]);
  });

  test('error response', () async {
    mock.enqueue(400, _raw('error.json'));

    await expectLater(
      client.ftn.auth(const FtnAuthRequest()),
      throwsA(isA<IdentisureException>()
          .having((e) => e.statusCode, 'statusCode', 400)
          .having((e) => e.message, 'message', contains('Invalid request'))),
    );
  });
}
