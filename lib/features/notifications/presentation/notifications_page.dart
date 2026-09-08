import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/errors/app_exception.dart';
import '../data/models/notification_model.dart';
import '../notification_type_mapper.dart';
import '../notifications_providers.dart';

final _firstPageProvider = FutureProvider.autoDispose<PaginatedNotifications>((ref) {
  return ref.watch(notificationsRepositoryProvider).getNotifications(page: 1);
});

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _markingAllRead = false;
  bool _markAllReadCooldown = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final firstPageAsync = ref.watch(_firstPageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.notifications),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: t.markAllAsRead,
            onPressed: () async {
              if (_markingAllRead || _markAllReadCooldown) return;
              setState(() => _markingAllRead = true);
              try {
                await ref.read(notificationsRepositoryProvider).markAllRead();
                ref.invalidate(_firstPageProvider);
                ref.invalidate(unreadCountProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.allNotificationsMarkedRead)),
                  );
                }
              } catch (e) {
                if (e is AppException) {
                  if (e.statusCode == 403) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.notificationAccessDenied)),
                      );
                    }
                  } else if (e.statusCode == 429) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.notificationTooManyRequests)),
                      );
                    }
                    setState(() => _markAllReadCooldown = true);
                    Future.delayed(const Duration(seconds: 10), () {
                      if (mounted) setState(() => _markAllReadCooldown = false);
                    });
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.notificationActionFailed)),
                      );
                    }
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.notificationActionFailed)),
                    );
                  }
                }
              } finally {
                if (mounted) setState(() => _markingAllRead = false);
              }
            },
          ),
        ],
      ),
      body: firstPageAsync.when(
        data: (page) => _NotificationsList(initialPage: page),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                e is AppException ? e.message : t.failedToLoadNotifications,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(_firstPageProvider),
                child: Text(t.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsList extends ConsumerStatefulWidget {
  final PaginatedNotifications initialPage;
  const _NotificationsList({required this.initialPage});

  @override
  ConsumerState<_NotificationsList> createState() => _NotificationsListState();
}

class _NotificationsListState extends ConsumerState<_NotificationsList> {
  late List<NotificationModel> _items;
  late bool _hasNext;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.initialPage.items);
    _hasNext = widget.initialPage.hasNext;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasNext || _isLoadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    setState(() => _isLoadingMore = true);
    try {
      final repo = ref.read(notificationsRepositoryProvider);
      final next = await repo.getNotifications(page: _currentPage + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(next.items);
        _hasNext = next.hasNext;
        _currentPage++;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
      if (mounted && e is AppException && e.statusCode == 403) {
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.notificationAccessDenied)),
        );
      }
    }
  }

  Future<void> _markRead(NotificationModel item) async {
    if (item.isRead) return;
    final idx = _items.indexWhere((e) => e.id == item.id);
    if (idx == -1) return;
    setState(() => _items[idx] = item.copyWith(isRead: true));
    try {
      await ref.read(notificationsRepositoryProvider).markRead(item.id.toString());
      ref.invalidate(unreadCountProvider);
    } catch (e) {
      if (e is AppException && e.statusCode == 409) {
        // Spec: on conflict, keep one canonical item and refetch rather than
        // reverting to the stale pre-optimistic-update value.
        try {
          final canonical = await ref
              .read(notificationsRepositoryProvider)
              .getNotificationDetail(item.id);
          if (mounted) setState(() => _items[idx] = canonical);
        } catch (_) {
          if (mounted) setState(() => _items[idx] = item);
        }
      } else {
        if (mounted) setState(() => _items[idx] = item);
      }
      if (mounted && e is AppException && e.statusCode == 403) {
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.notificationAccessDenied)),
        );
      }
    }
  }

  Future<bool> _confirmDelete(NotificationModel item) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.deleteConfirm),
        content: Text(t.notificationDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _delete(NotificationModel item) async {
    setState(() => _items.removeWhere((e) => e.id == item.id));
    try {
      await ref
          .read(notificationsRepositoryProvider)
          .deleteNotification(item.id.toString());
      if (!item.isRead) ref.invalidate(unreadCountProvider);
    } catch (e) {
      if (e is AppException) {
        if (e.statusCode == 404) {
          // Already deleted server-side — optimistic removal was correct,
          // nothing further to do.
          return;
        }
        if (e.statusCode == 403 && mounted) {
          final t = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.notificationAccessDenied)),
          );
          return;
        }
      }
      // Other errors: keep existing behavior — item stays removed from the
      // local list; it will reappear on next screen open if the delete
      // didn't actually succeed server-side.
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (_items.isEmpty) {
      return Center(
        child: Text(t.noNotificationsYet, style: Theme.of(context).textTheme.bodyLarge),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: _items.length + (_hasNext ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final item = _items[index];
        // REST уже отдаёт body как разобранный объект (в отличие от FCM
        // data, где body — JSON-строка) — decode здесь не нужен.
        final text = NotificationTextBuilder.buildText(t, item.type, item.body);
        final dateStr = item.createdAt != null
            ? DateFormat('dd.MM.yyyy HH:mm').format(item.createdAt!)
            : '';

        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(item),
          onDismissed: (_) => _delete(item),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: ListTile(
            leading: Icon(
              Icons.notifications_outlined,
              color: item.isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              text.title,
              style: TextStyle(
                fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: (text.body.isNotEmpty || dateStr.isNotEmpty)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (text.body.isNotEmpty) Text(text.body),
                      if (dateStr.isNotEmpty)
                        Text(dateStr, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  )
                : null,
            trailing: item.isRead
                ? null
                : Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
            onTap: () {
              _markRead(item);
              NotificationTypeMapper.handleTap(item.type);
            },
          ),
        );
      },
    );
  }
}
