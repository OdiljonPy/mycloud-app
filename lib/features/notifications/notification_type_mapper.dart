import 'package:flutter/material.dart';
import '../../core/services/navigation_service.dart';
import '../../l10n/app_localizations.dart';
import '../payment/presentation/pages/subscription_page.dart';
import '../payment/presentation/pages/add_card_page.dart';
import '../share/presentation/share_requests_page.dart';
import '../home/presentation/shared_page.dart';
import '../profile/presentation/profile_page.dart';
import 'presentation/notifications_page.dart';

/// Единственное место, которое нужно трогать при появлении новых типов
/// уведомлений или при изменении списка от бэкенда — карты type→экран и
/// type→текст, плюс сама навигация по тапу.
class NotificationTypeMapper {
  NotificationTypeMapper._();

  // Подтверждено реальной Swagger-схемой (enum поля "type", 15 значений).
  static final Map<String, WidgetBuilder> _routes = {
    'subscription_expiry_warning': (_) => const SubscriptionPage(),
    'subscription_expired': (_) => const SubscriptionPage(),
    'subscription_renewed': (_) => const SubscriptionPage(),
    'subscription_downgraded': (_) => const SubscriptionPage(),
    'payment_success': (_) => const SubscriptionPage(),
    'payment_failed': (_) => const SubscriptionPage(),
    'card_declined': (_) => const AddCardPage(),
    'file_shared': (_) => const SharedPage(),
    'file_share_revoked': (_) => const SharedPage(),
    'share_request_received': (_) => const ShareRequestsPage(),
    'share_request_approved': (_) => const ShareRequestsPage(),
    'share_request_rejected': (_) => const ShareRequestsPage(),
    'storage_warning': (_) => const ProfilePage(),
    'storage_full': (_) => const ProfilePage(),
    // Экран "Уведомления" появился в Этапе 8 — подходящего экрана под
    // конкретное объявление всё равно нет, поэтому просто открываем список.
    'system_announcement': (_) => const NotificationsPage(),
  };

  /// Текст по типу — теперь через AppLocalizations (en/ru/uz), не хардкод.
  /// Из body ничего не берёт: реальные ключи body не подтверждены
  /// бэкендом, гадать не стали по явной договорённости.
  static String labelFor(AppLocalizations l10n, String type) {
    switch (type) {
      case 'subscription_expiry_warning':
        return l10n.notifTypeSubscriptionExpiryWarning;
      case 'subscription_expired':
        return l10n.notifTypeSubscriptionExpired;
      case 'subscription_renewed':
        return l10n.notifTypeSubscriptionRenewed;
      case 'subscription_downgraded':
        return l10n.notifTypeSubscriptionDowngraded;
      case 'payment_success':
        return l10n.notifTypePaymentSuccess;
      case 'payment_failed':
        return l10n.notifTypePaymentFailed;
      case 'card_declined':
        return l10n.notifTypeCardDeclined;
      case 'file_shared':
        return l10n.notifTypeFileShared;
      case 'file_share_revoked':
        return l10n.notifTypeFileShareRevoked;
      case 'share_request_received':
        return l10n.notifTypeShareRequestReceived;
      case 'share_request_approved':
        return l10n.notifTypeShareRequestApproved;
      case 'share_request_rejected':
        return l10n.notifTypeShareRequestRejected;
      case 'system_announcement':
        return l10n.notifTypeSystemAnnouncement;
      case 'storage_warning':
        return l10n.notifTypeStorageWarning;
      case 'storage_full':
        return l10n.notifTypeStorageFull;
      default:
        return l10n.notifTypeUnknown;
    }
  }

  /// Безопасно достаёт строковое значение из body по ключу — без
  /// предположений о том, какие ключи там гарантированно есть.
  static String? bodyString(Map<String, dynamic> body, String key) {
    final value = body[key];
    return value?.toString();
  }

  static void handleTap(String? type) {
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) return;

    final builder = type != null ? _routes[type] : null;
    if (builder == null) {
      debugPrint('[NotificationTypeMapper] No route for type "$type"');
      return;
    }

    navigator.push(MaterialPageRoute(builder: builder));
  }
}
