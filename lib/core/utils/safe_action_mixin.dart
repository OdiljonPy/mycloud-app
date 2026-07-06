import 'package:flutter/widgets.dart';

/// Guards a widget's mutating actions (delete, purchase, upload, etc.)
/// against double-tap: a second call while one is still in flight is a no-op.
mixin SafeActionMixin<T extends StatefulWidget> on State<T> {
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;

  Future<void> safeAction(Future<void> Function() action) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
