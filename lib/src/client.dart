import 'package:http/http.dart' as http;

import 'bankid_no.dart';
import 'bankid_se.dart';
import 'document.dart';
import 'environment.dart';
import 'freja.dart';
import 'ftn.dart';
import 'mitid.dart';
import 'transport.dart';
import 'vipps.dart';

class IdkollenClient {
  IdkollenClient._(this._transport)
      : bankIdSe = BankIdSeEndpoint(_transport),
        bankIdNo = BankIdNoEndpoint(_transport),
        freja = FrejaEndpoint(_transport),
        mitId = MitIdEndpoint(_transport),
        ftn = FtnEndpoint(_transport),
        vipps = VippsEndpoint(_transport),
        document = DocumentEndpoint(_transport);

  final Transport _transport;

  final BankIdSeEndpoint bankIdSe;
  final BankIdNoEndpoint bankIdNo;
  final FrejaEndpoint freja;
  final MitIdEndpoint mitId;
  final FtnEndpoint ftn;
  final VippsEndpoint vipps;
  final DocumentEndpoint document;

  void close() => _transport.close();
}

class IdkollenClientBuilder {
  IdkollenClientBuilder(this.clientId, this.clientSecret);

  final String clientId;
  final String clientSecret;

  Environment _environment = Environment.production;
  String? _baseUrl;
  http.Client? _httpClient;

  IdkollenClientBuilder environment(Environment env) {
    _environment = env;
    return this;
  }

  IdkollenClientBuilder baseUrl(String url) {
    _baseUrl = url;
    return this;
  }

  IdkollenClientBuilder httpClient(http.Client client) {
    _httpClient = client;
    return this;
  }

  IdkollenClient build() {
    final transport = Transport(
      httpClient: _httpClient ?? http.Client(),
      baseUrl: _baseUrl ?? _environment.baseUrl,
      clientId: clientId,
      clientSecret: clientSecret,
    );
    return IdkollenClient._(transport);
  }
}
