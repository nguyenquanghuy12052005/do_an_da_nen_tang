import 'dart:convert';
import 'dart:io';

import '../domain/entities/sync_operation.dart';
import '../domain/repositories/sync_remote.dart';

class HttpSyncRemote implements SyncRemote {
  HttpSyncRemote({required this.baseUrl, required this.token});
  final String baseUrl;
  final String token;
  Future<Map<String, dynamic>> _request(
    String method,
    String path, [
    Object? body,
  ]) async {
    if (baseUrl.isEmpty || token.isEmpty) {
      throw StateError('Sync is not configured');
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      return await (() async {
        final request = await client.openUrl(
          method,
          Uri.parse('$baseUrl$path'),
        );
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        request.headers.contentType = ContentType.json;
        if (body != null) {
          final bytes = utf8.encode(jsonEncode(body));
          request.contentLength = bytes.length;
          request.add(bytes);
        }
        final response = await request.close();
        if (response.statusCode != 200) {
          throw HttpException('Sync HTTP ${response.statusCode}');
        }
        final bytes = await response.fold<List<int>>([], (buffer, chunk) {
          if (buffer.length + chunk.length > 1024 * 1024) {
            throw const FormatException('Response too large');
          }
          return buffer..addAll(chunk);
        });
        return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      })().timeout(const Duration(seconds: 10));
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> push(SyncOperation operation) async {
    final result = await _request('POST', '/v1/operations', operation.toJson());
    if (result['opId'] != operation.id) {
      throw const FormatException('Invalid acknowledgement');
    }
  }

  @override
  Future<SyncPage> pull(String? cursor) async {
    final result = await _request(
      'GET',
      '/v1/changes?cursor=${Uri.encodeQueryComponent(cursor ?? '0')}',
    );
    return SyncPage(
      records: (result['records'] as List)
          .map((r) => (r as Map).cast<String, Object?>())
          .toList(),
      cursor: result['cursor'] as String,
      hasMore: result['hasMore'] as bool,
    );
  }
}
