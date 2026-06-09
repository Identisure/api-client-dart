class AgeVerificationRequest {
  const AgeVerificationRequest({
    this.minAge,
    this.maxAge,
    this.refId,
    this.callbackUrl,
    this.redirectUrl,
  });

  final int? minAge;
  final int? maxAge;
  final String? refId;
  final String? callbackUrl;
  final String? redirectUrl;

  Map<String, dynamic> toJson() => {
        if (minAge != null) 'minAge': minAge,
        if (maxAge != null) 'maxAge': maxAge,
        if (refId != null) 'refId': refId,
        if (callbackUrl != null) 'callbackUrl': callbackUrl,
        if (redirectUrl != null) 'redirectUrl': redirectUrl,
      };
}

sealed class AgeVerificationStatus {
  factory AgeVerificationStatus.fromJson(Map<String, dynamic> json) {
    return switch (json['status']) {
      'PENDING' => AgeVerificationPending.fromJson(json),
      'COMPLETED' => AgeVerificationCompleted.fromJson(json),
      'FAILED' => AgeVerificationFailed.fromJson(json),
      _ => throw FormatException('Unknown age verification status: ${json['status']}'),
    };
  }
}

final class AgeVerificationPending implements AgeVerificationStatus {
  const AgeVerificationPending({
    required this.id,
    this.url,
    this.minAge,
    this.maxAge,
  });

  final String id;
  final String? url;
  final int? minAge;
  final int? maxAge;

  factory AgeVerificationPending.fromJson(Map<String, dynamic> json) =>
      AgeVerificationPending(
        id: json['id'] as String,
        url: json['url'] as String?,
        minAge: json['minAge'] as int?,
        maxAge: json['maxAge'] as int?,
      );
}

final class AgeVerificationCompleted implements AgeVerificationStatus {
  const AgeVerificationCompleted({required this.id, required this.ageVerified});

  final String id;
  final bool ageVerified;

  factory AgeVerificationCompleted.fromJson(Map<String, dynamic> json) =>
      AgeVerificationCompleted(
        id: json['id'] as String,
        ageVerified: json['ageVerified'] as bool,
      );
}

final class AgeVerificationFailed implements AgeVerificationStatus {
  const AgeVerificationFailed({required this.id, required this.error});

  final String id;
  final String error;

  factory AgeVerificationFailed.fromJson(Map<String, dynamic> json) =>
      AgeVerificationFailed(
        id: json['id'] as String,
        error: json['error'] as String,
      );
}
