import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../../data/models/payment_models.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PlansPage extends StatefulWidget {
  final int? currentPlanId;

  const PlansPage({super.key, this.currentPlanId});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  List<Plan> _allPlans = [];
  List<String> _periods = [];
  String? _selectedPeriod;
  final PageController _pageController = PageController(viewportFraction: 0.82);
  int _currentPage = 0;

  static const _bg = Color(0xFF0D0D1A);
  static const _accent = Color(0xFF3B82F6);
  static const _green = Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
    context.read<PaymentBloc>().add(const LoadPlansEvent());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPlansLoaded(List<Plan> plans) {
    final periodsOrdered = <String>[];
    final seen = <String>{};
    for (final p in plans) {
      if (seen.add(p.billingPeriod)) {
        periodsOrdered.add(p.billingPeriod);
      }
    }
    setState(() {
      _allPlans = plans;
      _periods = periodsOrdered;
      _selectedPeriod ??= periodsOrdered.isNotEmpty ? periodsOrdered.first : null;
    });
    _jumpToCurrentPlan();
  }

  void _jumpToCurrentPlan() {
    if (widget.currentPlanId == null) return;
    final filtered = _filteredPlans;
    final idx = filtered.indexWhere((p) => p.id == widget.currentPlanId);
    if (idx >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(idx);
          setState(() => _currentPage = idx);
        }
      });
    }
  }

  List<Plan> get _filteredPlans {
    if (_selectedPeriod == null) return _allPlans;
    return _allPlans.where((p) => p.billingPeriod == _selectedPeriod).toList();
  }

  void _prev() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _next() {
    final plans = _filteredPlans;
    if (_currentPage < plans.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _purchase(Plan plan) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.confirmPurchaseTitle,
            style: const TextStyle(color: Colors.white)),
        content: Text(
          l10n.confirmPurchaseMessage(
              plan.name, _formatPrice(plan.price), plan.billingPeriod),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel,
                style: const TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PaymentBloc>().add(PurchasePlanEvent(plan.id));
            },
            style: FilledButton.styleFrom(backgroundColor: _accent),
            child: Text(l10n.updatePlan),
          ),
        ],
      ),
    );
  }

  String _formatPrice(String raw) {
    final parts = raw.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '00';
    final buffer = StringBuffer();
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write(' ');
      buffer.write(intPart[i]);
      count++;
    }
    return '${buffer.toString().split('').reversed.join()}.$decPart';
  }

  String _formatStorage(int bytes) {
    if (bytes >= 1099511627776) {
      return '${(bytes / 1099511627776).toStringAsFixed(0)} ТБ';
    }
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(0)} ГБ';
    }
    if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(0)} МБ';
    }
    return '$bytes байт';
  }

  String _periodLabel(String period, AppLocalizations l10n) {
    switch (period.toLowerCase()) {
      case 'free': return l10n.freeLabel;
      case 'monthly': return l10n.billingMonthly;
      case 'yearly':
      case 'annual': return l10n.billingYearly;
      default:
        return period.isNotEmpty
            ? period[0].toUpperCase() + period.substring(1)
            : period;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PlansLoaded) {
            _onPlansLoaded(state.plans);
          } else if (state is PlanPurchased) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.response.message.isNotEmpty
                      ? state.response.message
                      : '${l10n.updatePlan}: ${state.response.planName}',
                ),
                backgroundColor: _green,
              ),
            );
            Navigator.pop(context);
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
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDragHandle(),
              _buildTopBar(l10n),
              if (_periods.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildPeriodTabs(),
              ],
              const SizedBox(height: 20),
              if (state is PaymentLoading && _allPlans.isEmpty)
                const SizedBox(
                  height: 280,
                  child: Center(
                    child: CircularProgressIndicator(color: _accent),
                  ),
                )
              else if (state is PaymentError && _allPlans.isEmpty)
                SizedBox(
                  height: 280,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.message,
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context
                              .read<PaymentBloc>()
                              .add(const LoadPlansEvent()),
                          style:
                              FilledButton.styleFrom(backgroundColor: _accent),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(height: 300, child: _buildCardsSection(l10n)),
              if (_allPlans.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDotIndicator(_filteredPlans.length),
              ],
              const SizedBox(height: 12),
              _buildFooterNote(l10n),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          );
        },
      ),
    ),
    );
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          const Spacer(),
          Text(
            l10n.plansTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ).animate().fadeIn(duration: 300.ms),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white70, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTabs() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: _periods.map((period) {
            final isActive = period == _selectedPeriod;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPeriod = period;
                    _currentPage = 0;
                  });
                  _pageController.jumpToPage(0);
                  _jumpToCurrentPlan();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    _periodLabel(period, l10n),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive
                          ? const Color(0xFF0D0D1A)
                          : Colors.white54,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildCardsSection(AppLocalizations l10n) {
    final plans = _filteredPlans;
    if (plans.isEmpty) {
      return Center(
        child: Text(l10n.noPlans,
            style: const TextStyle(color: Colors.white54)),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: plans.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (context, index) {
            final plan = plans[index];
            final isCurrent = plan.id == widget.currentPlanId;
            final l10n = AppLocalizations.of(context)!;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _PlanCard(
                plan: plan,
                isCurrent: isCurrent,
                storageLabel: _formatStorage(plan.storage),
                priceFormatted: _formatPrice(plan.price),
                periodLabel: _periodLabel(plan.billingPeriod, l10n),
                onPurchase: isCurrent ? null : () => _purchase(plan),
              ),
            ).animate(key: ValueKey('${_selectedPeriod}_$index'))
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.97, 0.97), curve: Curves.easeOut);
          },
        ),
        if (_currentPage > 0)
          Positioned(
            left: 6,
            child: _NavArrow(icon: Icons.chevron_left, onTap: _prev)
                .animate()
                .fadeIn(duration: 200.ms),
          ),
        if (_currentPage < _filteredPlans.length - 1)
          Positioned(
            right: 6,
            child: _NavArrow(icon: Icons.chevron_right, onTap: _next)
                .animate()
                .fadeIn(duration: 200.ms),
          ),
      ],
    );
  }

  Widget _buildDotIndicator(int count) {
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? _accent : Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildFooterNote(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 13, color: Colors.white30),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n.dataPreservedNote,
              style: const TextStyle(fontSize: 11.5, color: Colors.white30),
            ),
          ),
        ],
      ),
    ).animate(delay: 250.ms).fadeIn(duration: 300.ms);
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E30),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Icon(icon, color: const Color(0xFF3B82F6), size: 18),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final bool isCurrent;
  final String storageLabel;
  final String priceFormatted;
  final String periodLabel;
  final VoidCallback? onPurchase;

  static const _green = Color(0xFF22C55E);
  static const _accent = Color(0xFF3B82F6);
  static const _cardBg = Color(0xFF13131F);

  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.storageLabel,
    required this.priceFormatted,
    required this.periodLabel,
    this.onPurchase,
  });

  Color get _borderColor =>
      isCurrent ? _green : const Color(0xFF252538);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFree =
        plan.price == '0' || plan.price == '0.00' || plan.price.startsWith('0.');

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _borderColor,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrent
                ? _green.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBadge(isCurrent, l10n),
          const SizedBox(height: 14),
          Text(
            storageLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: isFree ? '0.00 UZS' : '$priceFormatted UZS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isFree ? l10n.freeLabel : '/ $periodLabel',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF252538), height: 1),
          const SizedBox(height: 12),
          _buildFeatures(l10n),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: isCurrent
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _green, width: 1.5),
                      foregroundColor: _green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.currentPlan,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  )
                : FilledButton(
                    onPressed: onPurchase,
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.updatePlan,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures(AppLocalizations l10n) {
    final features = plan.items.where((item) => item.isAvailable).toList();
    if (features.isEmpty) {
      return _FeatureRow(text: l10n.storageFeature(storageLabel));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FeatureRow(text: item.feature),
              ))
          .toList(),
    );
  }

  Widget _buildBadge(bool isCurrent, AppLocalizations l10n) {
    if (isCurrent) {
      return _Badge(label: l10n.currentPlan, color: _green);
    }
    return _Badge(
      label: plan.name,
      color: plan.isPopular ? _accent : const Color(0xFF4B5563),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.check_circle_outline,
              color: Color(0xFF22C55E), size: 15),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white60, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
