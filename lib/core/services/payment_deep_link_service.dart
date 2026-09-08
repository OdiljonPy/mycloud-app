import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class PaymentDeepLinkService {
  PaymentDeepLinkService._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _subscription;

  static final StreamController<Uri> _controller =
      StreamController<Uri>.broadcast();

  /// Emits only URIs matching scheme `bulutcha`, host/path `payment/return` —
  /// the return_url the iOS payment-link flow is launched with. Anything
  /// else on the `bulutcha` scheme (future reuse) is ignored here.
  static Stream<Uri> get paymentReturnStream => _controller.stream;

  static bool _isPaymentReturn(Uri uri) =>
      uri.scheme == 'bulutcha' &&
      uri.host == 'payment' &&
      uri.path == '/return';

  static Future<void> initialize() async {
    if (!Platform.isIOS) return;
    if (_subscription != null) return;

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null && _isPaymentReturn(initialUri)) {
        _controller.add(initialUri);
      }
    } catch (e) {
      debugPrint('[PaymentDeepLink] getInitialAppLink failed: $e');
    }

    _subscription = _appLinks.uriLinkStream.listen((uri) {
      if (_isPaymentReturn(uri)) _controller.add(uri);
    }, onError: (e) {
      debugPrint('[PaymentDeepLink] uriLinkStream error: $e');
    });
  }
}
