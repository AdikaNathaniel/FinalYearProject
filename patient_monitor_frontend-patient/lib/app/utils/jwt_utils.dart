class JwtUtils {
  static Map<String, dynamic> parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));

    return jsonDecode(decoded) as Map<String, dynamic>;
  }

  static bool isTokenExpired(String token) {
    final payload = parseJwt(token);
    final expiry = payload['exp'] as int;
    return DateTime.now().millisecondsSinceEpoch > expiry * 1000;
  }
}