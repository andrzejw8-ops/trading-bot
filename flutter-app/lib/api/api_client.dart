import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({required String baseUrl, required String token})
      : _base = baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _token = token;

  final String _base;
  final String _token;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

  Uri _u(String path, [Map<String, dynamic>? q]) =>
      Uri.parse('$_base$path').replace(queryParameters: q?.map((k, v) => MapEntry(k, '$v')));

  Future<Map<String, dynamic>> status() async {
    final r = await http.get(_u('/status'), headers: _headers);
    _ensureOk(r);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<void> start() async {
    final r = await http.post(_u('/start'), headers: _headers);
    _ensureOk(r);
  }

  Future<void> stop() async {
    final r = await http.post(_u('/stop'), headers: _headers);
    _ensureOk(r);
  }

  Future<List<dynamic>> logs({int limit = 200}) async {
    final r = await http.get(_u('/logs', {'limit': limit}), headers: _headers);
    _ensureOk(r);
    return jsonDecode(r.body) as List<dynamic>;
  }

  void _ensureOk(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('HTTP ${r.statusCode}: ${r.body}');
    }
  }
}
