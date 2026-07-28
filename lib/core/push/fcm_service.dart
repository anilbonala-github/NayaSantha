import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../api/api_client.dart';

/// Background isolate handler (must be top-level, entry-point annotated).
/// The OS renders "notification" pushes itself; this just keeps the isolate valid.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // No-op: server sends notification-type messages that the OS displays.
}

/// Firebase Cloud Messaging integration (Vol1 FCM). Best-effort throughout —
/// any failure (Firebase not yet configured on a platform, permission denied,
/// no APNs token on iOS) is swallowed so it never blocks the app.
class FcmService {
  FcmService._();

  /// Web push VAPID key ("Web Push certificates" key pair, Firebase → Cloud
  /// Messaging → Web configuration). Public value. Empty = web token skipped.
  static const String _webVapidKey =
      'BAhLB-oRVqbzP4frrqMRxdLKsHR-qaZUNOHhT9AguYfa8VFla_VxqZrabp7-Ley9MpMUPkKX31KS4wei7cnzdD0';

  static bool _initialised = false;
  static String? _lastToken;

  /// Initialise Firebase once at app start. No permission prompt here.
  static Future<void> init() async {
    if (_initialised) return;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
      }
      _initialised = true;
    } catch (e) {
      debugPrint('[fcm] init skipped: $e');
    }
  }

  /// Request permission, fetch the token and register it. Returns a human-readable
  /// status so a UI can show what happened. Call once authenticated.
  static Future<String> registerToken(ApiClient client) async {
    if (!_initialised) await init();
    if (!_initialised) return 'Firebase is not initialised on this device.';
    try {
      final messaging = FirebaseMessaging.instance;
      String permission = 'unknown';
      try {
        final settings = await messaging.requestPermission();
        permission = settings.authorizationStatus.name;
      } catch (_) {
        // On Android <13 permission is implicit; keep going and fetch the token.
      }

      if (kIsWeb && _webVapidKey.isEmpty) {
        return 'Web push key not configured yet.';
      }
      // getToken can transiently fail with SERVICE_NOT_AVAILABLE (Play services /
      // network not ready) — retry a few times with backoff before giving up.
      String? token;
      Object? lastError;
      for (int attempt = 1; attempt <= 4; attempt++) {
        try {
          token = kIsWeb
              ? await messaging.getToken(vapidKey: _webVapidKey)
              : await messaging.getToken();
          if (token != null && token.isNotEmpty) break;
        } catch (e) {
          lastError = e;
        }
        if (attempt < 4) await Future.delayed(Duration(seconds: 2 * attempt));
      }
      if (token == null || token.isEmpty) {
        final reason = lastError != null ? ' ($lastError)' : '';
        return 'Couldn’t get a push token yet$reason. This is usually a temporary '
            'Google Play services/network issue — try again on mobile data, update '
            'Google Play services, or reboot, then tap Enable again.';
      }

      await _post(client, token);
      _lastToken = token;
      messaging.onTokenRefresh.listen((t) {
        _lastToken = t;
        _post(client, t);
      });
      return 'Notifications enabled ✓ (permission: $permission, '
          'token …${token.substring(token.length - 6)}).';
    } catch (e) {
      return 'Could not enable notifications: $e';
    }
  }

  /// Remove this device's token (call on logout).
  static Future<void> unregister(ApiClient client) async {
    final token = _lastToken;
    _lastToken = null;
    if (token == null) return;
    try {
      await client.delete('/devices?fcmToken=${Uri.encodeQueryComponent(token)}');
    } catch (e) {
      debugPrint('[fcm] unregister skipped: $e');
    }
  }

  static Future<void> _post(ApiClient client, String token) async {
    final platform = kIsWeb
        ? 'WEB'
        : (defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID');
    await client.post('/devices', body: <String, dynamic>{
      'fcmToken': token,
      'platform': platform,
    });
  }
}
