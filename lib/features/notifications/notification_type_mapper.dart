import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/navigation_service.dart';
import '../../l10n/app_localizations.dart';
import '../payment/presentation/pages/subscription_page.dart';
import '../payment/presentation/pages/add_card_page.dart';
import '../payment/presentation/bloc/payment_bloc.dart';
import '../payment/data/repository/payment_repository.dart';
import '../share/presentation/share_requests_page.dart';
import '../home/presentation/shared_page.dart';
import '../profile/presentation/profile_page.dart';
import 'presentation/notifications_page.dart';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/navigation_service.dart';
import '../../l10n/app_localizations.dart';
import '../payment/presentation/pages/subscription_page.dart';
import '../payment/presentation/pages/add_card_page.dart';
import '../payment/presentation/bloc/payment_bloc.dart';
import '../payment/data/repository/payment_repository.dart';
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
    // iOS: ввод карты внутри приложения запрещён (App Store 3.1.1) — платёж
    // идёт только через внешнюю ссылку Click Shop, поэтому открываем
    // SubscriptionPage. Android — прежнее поведение, AddCardPage.
    'card_declined': (_) => Platform.isIOS
        ? const SubscriptionPage()
        : BlocProvider<PaymentBloc>(
            create: (_) => PaymentBloc(PaymentRepository()),
            child: const AddCardPage(),
          ),
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

/// Чистая функция (l10n, type, body) → (title, body) с интерполяцией
/// реальных полей body. Отдельный класс от NotificationTypeMapper, чтобы не
/// смешивать ответственность "текст" с ответственностью "роутинг по тапу"
/// (labelFor/handleTap/_routes) в одном классе.
///
/// Не зависит от BuildContext — единственная причина существования этого
/// класса: должен одинаково работать и в UI (список уведомлений), и в
/// background isolate FCM, где BuildContext в принципе недоступен.
class NotificationTextBuilder {
  NotificationTextBuilder._();

  static String _s(dynamic value) => value?.toString() ?? '';

  static List<dynamic> _list(dynamic value) => value is List ? value : const [];

  static ({String title, String body}) buildText(
    AppLocalizations l10n,
    String type,
    Map<String, dynamic> body,
  ) {
    switch (type) {
      case 'subscription_expiry_warning':
        return (
          title: l10n.notifTypeSubscriptionExpiryWarning,
          body: l10n.notifBodySubscriptionExpiryWarning(
            _s(body['plan']),
            _s(body['days']),
          ),
        );
      case 'subscription_expired':
        return (
          title: l10n.notifTypeSubscriptionExpired,
          body: l10n.notifBodySubscriptionExpired(_s(body['plan'])),
        );
      case 'subscription_renewed':
        return (
          title: l10n.notifTypeSubscriptionRenewed,
          body: l10n.notifBodySubscriptionRenewed(_s(body['plan'])),
        );
      case 'subscription_downgraded':
        return (
          title: l10n.notifTypeSubscriptionDowngraded,
          body: l10n.notifBodySubscriptionDowngraded(_s(body['plan'])),
        );
      case 'payment_success':
        return (
          title: l10n.notifTypePaymentSuccess,
          body: l10n.notifBodyPaymentSuccess(_s(body['amount']), _s(body['plan'])),
        );
      case 'payment_failed':
        return (
          title: l10n.notifTypePaymentFailed,
          body: l10n.notifBodyPaymentFailed(
            _s(body['amount']),
            _s(body['plan']),
            _s(body['error']),
          ),
        );
      case 'card_declined':
        return (
          title: l10n.notifTypeCardDeclined,
          body: l10n.notifBodyCardDeclined(_s(body['last4']), _s(body['plan'])),
        );
      case 'file_shared':
        return (
          title: l10n.notifTypeFileShared,
          body: _fileSharedBody(l10n, body, revoked: false),
        );
      case 'file_share_revoked':
        return (
          title: l10n.notifTypeFileShareRevoked,
          body: _fileSharedBody(l10n, body, revoked: true),
        );
      case 'share_request_received':
        return (
          title: l10n.notifTypeShareRequestReceived,
          body: l10n.notifBodyShareRequestReceived(
            _s(body['requester']),
            _s(body['item_name']),
          ),
        );
      case 'share_request_approved':
        return (
          title: l10n.notifTypeShareRequestApproved,
          body: l10n.notifBodyShareRequestApproved(_s(body['item_name'])),
        );
      case 'share_request_rejected':
        return (
          title: l10n.notifTypeShareRequestRejected,
          body: l10n.notifBodyShareRequestRejected(_s(body['item_name'])),
        );
      case 'storage_warning':
        return (
          title: l10n.notifTypeStorageWarning,
          body: l10n.notifBodyStorageWarning(_s(body['used_percent'])),
        );
      case 'storage_full':
        return (
          title: l10n.notifTypeStorageFull,
          body: l10n.notifBodyStorageFull(
            _s(body['used_bytes']),
            _s(body['limit_bytes']),
          ),
        );
      case 'storage_deletion_warning':
        // Нет в исходных 15 типах _routes/labelFor — своего роута/лейбла не
        // было, поэтому заголовок берём из нового ключа, а не переиспользуем
        // чужой label.
        return (
          title: l10n.notifTypeStorageDeletionWarning,
          body: l10n.notifBodyStorageDeletionWarning(
            _s(body['deletion_date']),
            _s(body['days_left']),
          ),
        );
      case 'system_announcement':
        // Единственный тип, где сам бэкенд может прислать готовый
        // человекочитаемый текст в body — используем его как есть, без
        // l10n-интерполяции, если он есть.
        final title = body['title'] as String?;
        final message = body['message'] as String?;
        return (
          title: (title != null && title.isNotEmpty)
              ? title
              : l10n.notifTypeSystemAnnouncement,
          body: (message != null && message.isNotEmpty)
              ? message
              : l10n.notifBodySystemAnnouncementFallback,
        );
      default:
        return (title: l10n.notifTypeUnknown, body: '');
    }
  }

  /// file_shared/file_share_revoked: names — массив из 1 элемента при ровно
  /// одном файле/папке, пустой [] при нескольких (контракт бэкенда). Во
  /// втором случае считаем количество по file_ids+folder_ids.
  static String _fileSharedBody(
    AppLocalizations l10n,
    Map<String, dynamic> body, {
    required bool revoked,
  }) {
    final sharedBy = _s(body['shared_by']);
    final names = _list(body['names']);
    if (names.length == 1) {
      final name = _s(names.first);
      return revoked
          ? l10n.notifBodyFileShareRevokedSingle(sharedBy, name)
          : l10n.notifBodyFileSharedSingle(sharedBy, name);
    }
    final count = _list(body['file_ids']).length + _list(body['folder_ids']).length;
    return revoked
        ? l10n.notifBodyFileShareRevokedMultiple(sharedBy, count.toString())
        : l10n.notifBodyFileSharedMultiple(sharedBy, count.toString());
  }
}
