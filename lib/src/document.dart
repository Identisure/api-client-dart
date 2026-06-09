import 'transport.dart';

class DocumentUploadResponse {
  const DocumentUploadResponse({required this.id, required this.hash});
  final String id;
  final String hash;
  factory DocumentUploadResponse.fromJson(Map<String, dynamic> json) =>
      DocumentUploadResponse(id: json['id'] as String, hash: json['hash'] as String);
}

class DocumentEndpoint {
  DocumentEndpoint(this._transport);
  final Transport _transport;

  Future<DocumentUploadResponse> upload(List<int> data, String filename, {String mimeType = 'application/pdf'}) async {
    final body = await _transport.postMultipart('/document', data, filename, mimeType);
    return DocumentUploadResponse.fromJson(body);
  }

  Future<List<int>> download(String id) => _transport.getRaw('/document/$id');

  Future<void> delete(String id) => _transport.delete('/document/$id');
}
