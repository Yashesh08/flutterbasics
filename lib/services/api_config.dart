import 'package:flutter/foundation.dart';

/// Returns the correct API base URL depending on the platform:
/// • Chrome/Web: http://localhost:3000
/// • Android Emulator: http://10.0.2.2:3000
/// • Windows / macOS / Linux / iOS: http://localhost:3000
/// • Overridable via --dart-define=API_BASE_URL=...
String get defaultApiBaseUrl {
  const envUrl = String.fromEnvironment('API_BASE_URL');
  if (envUrl.isNotEmpty) {
    return envUrl;
  }

  if (kIsWeb) {
    return 'http://localhost:3000';
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000';
  }

  return 'http://localhost:3000';
}
