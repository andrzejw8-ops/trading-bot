import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  static const _kToken = 'api_token';
  static const _kBase = 'api_base';
  static const _storage = FlutterSecureStorage();

  Future<void> save({required String baseUrl, required String token}) async {
    await _storage.write(key: _kBase, value: baseUrl);
    await _storage.write(key: _kToken, value: token);
  }

  Future<(String?, String?)> load() async {
    final base = await _storage.read(key: _kBase);
    final tok = await _storage.read(key: _kToken);
    return (base, tok);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kBase);
    await _storage.delete(key: _kToken);
  }
}
