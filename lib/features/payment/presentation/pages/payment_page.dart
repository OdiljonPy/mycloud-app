import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/payment_models.dart';
import '../../data/repository/payment_repository.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import 'add_card_page.dart';
import 'plans_page.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PaymentBloc(PaymentRepository())..add(const LoadPaymentData()),
      child: const _PaymentView(),
    );
  }
}

class _PaymentView extends StatefulWidget {
  const _PaymentView();

  @override
  State<_PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<_PaymentView> {
  PaymentDataLoaded? _lastLoaded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.paymentAndSubscription),
        centerTitle: true,
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is CardDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.cardDeleted)),
            );
            context.read<PaymentBloc>().add(const LoadPaymentData());
          } else if (state is CardSetDefault) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.cardSetAsDefault)),
            );
            context.read<PaymentBloc>().add(const LoadPaymentData());
          } else if (state is PaymentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PaymentDataLoaded) {
            _lastLoaded = state;
            return _PaymentContent(
              cards: state.cards,
              subscription: state.subscription,
            );
          }
          if (_lastLoaded != null && state is! PaymentError) {
            return _PaymentContent(
              cards: _lastLoaded!.cards,
              subscription: _lastLoaded!.subscription,
            );
          }
          if (state is PaymentError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context
                        .read<PaymentBloc>()
                        .add(const LoadPaymentData()),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _PaymentContent extends StatelessWidget {
  final List<CardToken> cards;
  final CurrentSubscription? subscription;

  const _PaymentContent({
    required this.cards,
    required this.subscription,
  });

  String _formatBytes(int bytes) {
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(2)} ГБ';
    }
    if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(1)} МБ';
    }
    return '$bytes байт';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PaymentBloc>().add(const LoadPaymentData());
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SubscriptionCard(
            subscription: subscription,
            formatBytes: _formatBytes,
            onChangePlan: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => BlocProvider.value(
                  value: context.read<PaymentBloc>(),
                  child: PlansPage(currentPlanId: subscription?.planId),
                ),
              ).then((_) {
                if (context.mounted) {
                  context.read<PaymentBloc>().add(const LoadPaymentData());
                }
              });
            },
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, curve: Curves.easeOut),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.myCards,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<PaymentBloc>(),
                      child: const AddCardPage(),
                    ),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: Text(l10n.addCard),
              ),
            ],
          ).animate(delay: 150.ms).fadeIn(duration: 350.ms).slideY(begin: 0.04, curve: Curves.easeOut),
          const SizedBox(height: 8),
          if (cards.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  l10n.noCardsLinked,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 350.ms)
          else
            ...List.generate(
              cards.length,
              (i) => _CardTile(card: cards[i])
                  .animate(delay: (200 + i * 80).ms)
                  .fadeIn(duration: 350.ms)
                  .slideX(begin: 0.04, curve: Curves.easeOut),
            ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final CurrentSubscription? subscription;
  final String Function(int) formatBytes;
  final VoidCallback onChangePlan;

  const _SubscriptionCard({
    required this.subscription,
    required this.formatBytes,
    required this.onChangePlan,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sub = subscription;
    final hasSubscription = sub != null && sub.planId != null;
    final usedFraction = (sub != null && sub.storageLimit > 0)
        ? sub.usedStorage / sub.storageLimit
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasSubscription
                    ? (sub.planName ?? l10n.currentPlan)
                    : l10n.noSubscription,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasSubscription && sub.billingPeriod != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sub.billingPeriod!,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: usedFraction.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.storageUsed(formatBytes(sub?.usedStorage ?? 0)),
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                formatBytes(sub?.storageLimit ?? 0),
                style:
                    const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          if (sub?.endsAt != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.subscriptionUntil(_formatDate(sub!.endsAt!)),
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onChangePlan,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(hasSubscription ? l10n.changePlan : l10n.choosePlan),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _CardTile extends StatelessWidget {
  final CardToken card;

  const _CardTile({required this.card});

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'active':
        return l10n.cardStatusActive;
      case 'pending':
        return l10n.cardStatusPending;
      case 'blocked':
        return l10n.cardStatusBlocked;
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'blocked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: card.isDefault
            ? const BorderSide(color: Color(0xFF1A73E8), width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.credit_card, color: Color(0xFF1A73E8)),
        ),
        title: Text(
          card.maskedCardNumber,
          style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1),
        ),
        subtitle: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(card.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _statusLabel(card.status, l10n),
                style: TextStyle(
                    fontSize: 11, color: _statusColor(card.status)),
              ),
            ),
            if (card.isDefault) ...[
              const SizedBox(width: 8),
              const Icon(Icons.star, size: 14, color: Color(0xFF1A73E8)),
              Text(
                ' ${l10n.cardDefaultLabel}',
                style:
                    const TextStyle(fontSize: 11, color: Color(0xFF1A73E8)),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'default') {
              context
                  .read<PaymentBloc>()
                  .add(SetDefaultCardEvent(card.id));
            } else if (value == 'delete') {
              _confirmDelete(context, l10n);
            }
          },
          itemBuilder: (_) => [
            if (!card.isDefault)
              PopupMenuItem(
                value: 'default',
                child: Row(
                  children: [
                    const Icon(Icons.star_outline, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.setAsDefault),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteCardTitle),
        content: Text(l10n.deleteCardMessage(card.maskedCardNumber)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PaymentBloc>().add(DeleteCardEvent(card.id));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
