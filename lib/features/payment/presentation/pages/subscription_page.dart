import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/payment_models.dart';
import '../../data/repository/payment_repository.dart';
import '../../../profile/data/profile_repository.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import 'add_card_page.dart';
import '../widgets/card_preview_widget.dart';
import '../../../../core/utils/plan_localizer.dart';
import '../../../../core/utils/plan_style.dart';
import '../../../../core/utils/error_localizer.dart';
import '../../../../core/utils/format_bytes.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PaymentBloc(PaymentRepository())
        ..add(const LoadPaymentData())
        ..add(const LoadPlansEvent()),
      child: const _SubscriptionView(),
    );
  }
}

class _SubscriptionView extends StatefulWidget {
  const _SubscriptionView();

  @override
  State<_SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<_SubscriptionView> {
  final _profileRepo = ProfileRepository();

  PaymentDataLoaded? _paymentData;
  List<Plan> _plans = [];
  int? _selectedPlanId;
  int _usedStorageBytes = 0;
  bool _isLoadingStorage = false;

  static const _accent = Color(0xFF1A73E8);
  static const _green = Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
    _loadStorage();
  }

  Future<void> _loadStorage() async {
    if (_isLoadingStorage) return;
    _isLoadingStorage = true;
    try {
      final data = await _profileRepo.getStorageUsed();
      if (!mounted) return;
      setState(() {
        _usedStorageBytes = (data['used_storage'] as num?)?.toInt() ?? 0;
      });
    } catch (_) {
      // Storage usage is only needed for the downgrade warning; ignore failures.
    } finally {
      _isLoadingStorage = false;
    }
  }

  String _formatBytes(int bytes) =>
      formatBytes(bytes, AppLocalizations.of(context)!);

  String _formatPrice(String raw) {
    final intPart = raw.split('.')[0];
    final buffer = StringBuffer();
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write(' ');
      buffer.write(intPart[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join();
  }

  bool _isFreePlan(Plan plan) => double.tryParse(plan.price) == 0;

  CardToken? _primaryCard(List<CardToken> cards) {
    if (cards.isEmpty) return null;
    return cards.firstWhere((c) => c.isDefault, orElse: () => cards.first);
  }

  void _openAddCard() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<PaymentBloc>(),
              child: const AddCardPage(),
            ),
          ),
        )
        .then((_) {
      if (mounted) context.read<PaymentBloc>().add(const LoadPaymentData());
    });
  }

  void _onSwitchPressed(CurrentSubscription? subscription) {
    final plan = _plans.firstWhere(
      (p) => p.id == _selectedPlanId,
      orElse: () => _plans.first,
    );
    final isDowngrade = subscription != null &&
        subscription.planId != null &&
        plan.storage < subscription.storageLimit;

    if (isDowngrade && _usedStorageBytes > plan.storage) {
      _showDowngradeWarning(plan);
    } else {
      context.read<PaymentBloc>().add(PurchasePlanEvent(plan.id));
    }
  }

  void _showDowngradeWarning(Plan plan) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.downgradeWarningTitle),
        content: Text(
          l10n.downgradeWarningMessage(
            _formatBytes(_usedStorageBytes),
            PlanLocalizer.localize(plan.name, l10n),
            _formatBytes(plan.storage),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.staySamePlan),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PaymentBloc>().add(PurchasePlanEvent(plan.id));
            },
            child: Text(l10n.continueAnyway),
          ),
        ],
      ),
    );
  }

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
          if (state is PaymentDataLoaded) {
            setState(() {
              _paymentData = state;
              _selectedPlanId ??= state.subscription?.planId;
            });
          } else if (state is PlansLoaded) {
            setState(() => _plans = state.plans);
          } else if (state is PlanPurchased) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.response.message.isNotEmpty
                      ? state.response.message
                      : l10n.updatePlan,
                ),
                backgroundColor: _green,
              ),
            );
            context.read<PaymentBloc>().add(const LoadPaymentData());
            _loadStorage();
          } else if (state is CardDeleted) {
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
                content: Text(ErrorLocalizer.forException(state.error, l10n)),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final stillLoading = _paymentData == null &&
              _plans.isEmpty &&
              (state is PaymentLoading || state is PaymentInitial);
          if (stillLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final cards = _paymentData?.cards ?? [];
          final subscription = _paymentData?.subscription;
          final busy = state is PaymentLoading;
          final paidPlans = _plans.where((p) => !_isFreePlan(p)).toList();
          final freePlans = _plans.where(_isFreePlan).toList();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<PaymentBloc>().add(const LoadPaymentData());
              context
                  .read<PaymentBloc>()
                  .add(const LoadPlansEvent(forceRefresh: true));
              await _loadStorage();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PrimaryCardWidget(card: _primaryCard(cards), onTap: _openAddCard)
                    .animate()
                    .fadeIn(duration: 350.ms),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.myCards,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: _openAddCard,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addCard),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (cards.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(l10n.noCardsLinked,
                          style: const TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ...List.generate(
                    cards.length,
                    (i) => _CardTile(card: cards[i], disabled: busy),
                  ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  l10n.plansTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (_plans.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(l10n.noPlans,
                          style: const TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ...[
                    ...List.generate(paidPlans.length, (i) {
                      final plan = paidPlans[i];
                      return _PlanListTile(
                        plan: plan,
                        isCurrent: plan.id == subscription?.planId,
                        isSelected: plan.id == _selectedPlanId,
                        priceFormatted: _formatPrice(plan.price),
                        onTap: () => setState(() => _selectedPlanId = plan.id),
                      ).animate(delay: (i * 40).ms).fadeIn(duration: 250.ms);
                    }),
                    ...freePlans.map(
                      (plan) => _PlanListTile(
                        plan: plan,
                        isCurrent: plan.id == subscription?.planId,
                        isSelected: plan.id == _selectedPlanId,
                        priceFormatted: _formatPrice(plan.price),
                        isFreeCompact: true,
                        onTap: () => setState(() => _selectedPlanId = plan.id),
                      ),
                    ),
                  ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: (!busy &&
                            _selectedPlanId != null &&
                            _selectedPlanId != subscription?.planId)
                        ? () => _onSwitchPressed(subscription)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.switchPlanButton),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PrimaryCardWidget extends StatelessWidget {
  final CardToken? card;
  final VoidCallback onTap;

  const _PrimaryCardWidget({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = card;

    if (c == null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_circle_outline, color: Color(0xFF1A73E8)),
                const SizedBox(width: 8),
                Text(
                  l10n.addCardPrompt,
                  style: const TextStyle(
                    color: Color(0xFF1A73E8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        CardPreviewWidget(
          numberText: c.maskedCardNumber,
          detectionDigits: c.maskedCardNumber.replaceAll(RegExp(r'[^0-9]'), ''),
        ),
        if (c.isDefault)
          const Positioned(
            top: 24,
            right: 24,
            child: Icon(Icons.star, color: Colors.white, size: 18),
          ),
      ],
    );
  }
}

class _PlanListTile extends StatelessWidget {
  final Plan plan;
  final bool isCurrent;
  final bool isSelected;
  final String priceFormatted;
  final bool isFreeCompact;
  final VoidCallback onTap;

  static const _green = Color(0xFF22C55E);
  static const _accent = Color(0xFF1A73E8);
  static const _cardBg = Color(0xFFFFFFFF);
  static const _borderNormal = Color(0xFFE5E7EB);
  static const _borderTarget = Color(0xFF0066FF);
  static const _borderFree = Color(0xFFCBD5E1);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _darkCardBg = Color(0xFF161B22);
  static const _darkBorderNormal = Color(0xFF30363D);
  static const _darkTextPrimary = Color(0xFFE6EDF3);
  static const _darkTextSecondary = Color(0xFF8B949E);
  static const _targetPlanBytes = 214748364800; // 200 GB

  const _PlanListTile({
    required this.plan,
    required this.isCurrent,
    required this.isSelected,
    required this.priceFormatted,
    this.isFreeCompact = false,
    required this.onTap,
  });

  String _formatStorage(int bytes, AppLocalizations l10n) {
    if (bytes >= 1099511627776) {
      return '${(bytes / 1099511627776).toStringAsFixed(0)} ${l10n.unitTb}';
    }
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(0)} ${l10n.unitGb}';
    }
    if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(0)} ${l10n.unitMb}';
    }
    return '$bytes ${l10n.unitBytes}';
  }

  String _periodSuffix(AppLocalizations l10n) {
    final period = plan.billingPeriod.toLowerCase();
    final isYearly = period == 'yearly' || period == 'annual';
    return isYearly ? l10n.planPeriodYearly : l10n.planPeriodMonthly;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFree = double.tryParse(plan.price) == 0;
    final isTarget =
        !isFreeCompact && (plan.isPopular || plan.storage == _targetPlanBytes);
    final style = PlanStyle.forName(plan.name);
    final textPrimary = isDark ? _darkTextPrimary : _textPrimary;
    final textSecondary = isDark ? _darkTextSecondary : _textSecondary;

    final Color background;
    final Color borderColor;
    final double borderWidth;
    final List<BoxShadow>? boxShadow;

    if (isFreeCompact) {
      background = Colors.transparent;
      final baseBorderColor = isDark ? _darkBorderNormal : _borderFree;
      borderColor = isCurrent ? _green : (isSelected ? _accent : baseBorderColor);
      borderWidth = (isCurrent || isSelected) ? 2.0 : 1.0;
      boxShadow = null;
    } else {
      background = isDark ? _darkCardBg : _cardBg;
      final baseBorderColor =
          isTarget ? _borderTarget : (isDark ? _darkBorderNormal : _borderNormal);
      final baseBorderWidth = isTarget ? 1.5 : 0.5;
      borderColor = isCurrent ? _green : (isSelected ? _accent : baseBorderColor);
      borderWidth = (isCurrent || isSelected) ? 2.0 : baseBorderWidth;
      boxShadow = isDark
          ? null
          : (isTarget
              ? const [
                  BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 2,
                      offset: Offset(0, 1)),
                  BoxShadow(
                      color: Color(0x1A0066FF),
                      blurRadius: 20,
                      offset: Offset(0, 4)),
                ]
              : const [
                  BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 2,
                      offset: Offset(0, 1)),
                  BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 12,
                      offset: Offset(0, 4)),
                ]);
    }

    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: isFreeCompact
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
          : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: background,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: boxShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? style.iconColor.withValues(alpha: 0.18)
                  : style.iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(style.icon, color: style.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PlanLocalizer.localize(plan.name, l10n),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary),
                ),
                const SizedBox(height: 4),
                Text(_formatStorage(plan.storage, l10n),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary)),
                const SizedBox(height: 2),
                isFree
                    ? Text(
                        l10n.freeLabel,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary),
                      )
                    : RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          children: [
                            TextSpan(
                              text: '$priceFormatted UZS',
                              style: TextStyle(color: textPrimary),
                            ),
                            TextSpan(
                              text: _periodSuffix(l10n),
                              style: TextStyle(color: textSecondary),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
          if (isCurrent)
            const Icon(Icons.check_circle, color: _green)
          else
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? _accent : textSecondary,
            ),
        ],
      ),
    );

    final showPopularBadge = isTarget && !isCurrent;
    final content = showPopularBadge
        ? Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                card,
                Positioned(
                  top: -12,
                  left: 16,
                  child: _PopularBadge(text: l10n.popularBadge),
                ),
              ],
            ),
          )
        : card;

    return GestureDetector(
      onTap: isCurrent ? null : onTap,
      child: content,
    );
  }
}

class _PopularBadge extends StatelessWidget {
  final String text;

  const _PopularBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0066FF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x330066FF), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final CardToken card;
  final bool disabled;

  const _CardTile({required this.card, this.disabled = false});

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
          enabled: !disabled,
          onSelected: (value) {
            if (value == 'default') {
              context.read<PaymentBloc>().add(SetDefaultCardEvent(card.id));
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
