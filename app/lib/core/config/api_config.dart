class ApiConfig {
  // Alamat bisa diganti saat run: --dart-define=API_BASE=...
  // Default: emulator Android. Chrome: localhost | HP asli: IP laptop (lihat SETUP.md)
  static const baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2/nestalla-api/api',
  );

  static String avatarUrl(String filename) =>
      '${baseUrl.replaceFirst(RegExp(r'/api$'), '')}/image/avatars/$filename';

  static String bookCoverUrl(String filename) =>
      '${baseUrl.replaceFirst(RegExp(r'/api$'), '')}/image/covers/$filename';
}
