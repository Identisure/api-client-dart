<img align="left" height="100" style="margin-right: 10px;" src="../img/icon.png">

# IDkollen Dart Client

[![pub.dev version][pub-image]][pub-url]
[![MIT license][license-image]][license-url]

[pub-image]: https://img.shields.io/pub/v/idkollen_client?style=flat-square
[pub-url]: https://pub.dev/packages/idkollen_client
[license-image]: https://img.shields.io/badge/license-MIT-blue?style=flat-square
[license-url]: https://opensource.org/license/mit

API client for the [IDkollen](https://developers.idkollen.se) REST API.

## Installation

```sh
dart pub add idkollen_client
```

## Usage

```dart
import 'package:idkollen_client/idkollen_client.dart';

Future<void> main() async {
  final client = IdkollenClientBuilder('client_id', 'client_secret')
      .environment(Environment.staging)
      .build();

  final session = await client.bankIdSe.auth(const BankIdSeAuthRequest());
  if (session is BankIdSePending) {
    print('Session ID: ${session.id}');

    final result = await client.bankIdSe.waitForAuth(session.id);
    final message = switch (result) {
      BankIdSeCompleted(:final name, :final ssn) => 'Authenticated: $name ($ssn)',
      BankIdSeFailed(:final error) => 'Failed: $error',
      BankIdSePending() => 'Still pending',
    };
    print(message);
  }

  client.close();
}
```

## Development

### Prerequisites

- Dart 3.0+

### Build / Test / Analyze

```sh
dart pub get
dart test
dart analyze
```
