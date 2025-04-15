import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // API Base URLs for different environments
  static const String _prodApiUrl = 'https://your-production-api.com/api';
  static const String _stagingApiUrl =
      'https://staging-api.your-domain.com/api';

  // For local development
  static const String _localApiUrl =
      'http://10.0.2.2:8000/api'; // For Android emulator
  static const String _localIosApiUrl =
      'http://localhost:8000/api'; // For iOS simulator
  static const String _localWindowsApiUrl =
      'http://localhost:8000/api'; // For Windows

  // Your actual network IP (update this with your computer's IP address)
  static const String _networkIpApiUrl =
      'http://192.168.1.100:8000/api'; // Change to your IP

  // Current environment
  static const Environment _environment = Environment.development;

  // Get the appropriate base URL based on platform and environment
  static String get apiBaseUrl {
    if (_environment == Environment.production) {
      return _prodApiUrl;
    } else if (_environment == Environment.staging) {
      return _stagingApiUrl;
    } else {
      // Development environment - different URLs depending on platform
      if (kIsWeb) {
        return _localIosApiUrl; // Use localhost for web
      } else if (Platform.isAndroid) {
        return _localApiUrl; // Use 10.0.2.2 for Android emulator
      } else if (Platform.isIOS) {
        return _localIosApiUrl; // Use localhost for iOS simulator
      } else if (Platform.isWindows) {
        return _localWindowsApiUrl; // Use localhost for Windows
      } else {
        // For other desktop platforms or real devices, use the network IP
        return _networkIpApiUrl;
      }
    }
  }

  // Get appropriate connection method description for troubleshooting
  static String get connectionHelp {
    if (_environment != Environment.development) {
      return 'Make sure you have an internet connection.';
    }

    if (kIsWeb) {
      return 'Make sure Django is running on http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'Make sure Django is running on your computer and accessible at http://10.0.2.2:8000 from the Android emulator.';
    } else if (Platform.isIOS) {
      return 'Make sure Django is running on your computer and accessible at http://localhost:8000 from the iOS simulator.';
    } else if (Platform.isWindows) {
      return 'Make sure Django is running on http://localhost:8000 and that no firewall is blocking the connection.';
    } else {
      return 'Make sure Django is running on your computer and your device can access your computer\'s network at ${_networkIpApiUrl.split('/api')[0]}';
    }
  }

  // Check if we're running as an executable on desktop
  static bool get isDesktopExe {
    return !kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  }
}

enum Environment {
  development,
  staging,
  production,
}
