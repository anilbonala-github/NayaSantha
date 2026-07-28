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

  /// Web push requires a VAPID key. Paste the "Web Push certificates" key pair
  /// from Firebase → Cloud Messaging → Web configuration. Empty = web token skipped.
  static const String _webVapidKey = '';

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

  /// Request permission, fetch the token and register it. Call once authenticated.
  static Future<void> registerToken(ApiClient client) async {
    if (!_initialised) await init();
    if (!_initialised) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      if (kIsWeb && _webVapidKey.isEmpty) {
        debugPrint('[fcm] web VAPID key not set — skipping web token');
        return;
      }
      final token = kIsWeb
          ? await messaging.getToken(vapidKey: _webVapidKey)
          : await messaging.getToken();
      if (token == null || token.isEmpty) return;

      await _post(client, token);
      _lastToken = token;
      messaging.onTokenRefresh.listen((t) {
        _lastToken = t;
        _post(client, t);
      });
    } catch (e) {
      debugPrint('[fcm] register skipped: $e');
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
