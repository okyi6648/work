class ApiConstants {
  static const String baseUrl = 'http://localhost:8080/api/v1';

  // Auth endpoints
  static const String smsSend = '/auth/sms/send';
  static const String smsVerify = '/auth/sms/verify';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // OCR endpoints
  static const String ocrExtract = '/ocr/extract';

  // Query endpoints
  static const String query = '/query';
  static const String queryBatch = '/query/batch';

  // Report endpoints
  static const String reports = '/reports';
  static const String myReports = '/reports/mine';

  // Upload endpoints
  static const String uploadPresign = '/upload/presign';

  // Appeal endpoints
  static const String appeals = '/appeals';

  // Community endpoints
  static const String posts = '/posts';

  // Alert endpoints
  static const String alerts = '/alerts';
  static const String alertsLatest = '/alerts/latest';
}
