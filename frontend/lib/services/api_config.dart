class ApiConfig {
  static const String baseHost = 'https://saral-sewa.onrender.com';
  static const String apiPrefix = '/api';

  static String endpoint(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return '$baseHost$apiPrefix$normalized';
  }
}
