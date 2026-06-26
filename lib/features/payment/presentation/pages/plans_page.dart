import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../../data/models/payment_models.dart';
import '../../../../l10n/app_localizations.dart';

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
  final PageController _pageController = PageController(viewportFraction: 0.78);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _bg,
      body: BlocConsumer<PaymentBloc, PaymentState>(
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
          return SafeArea(
            child: Column(
              children: [
                _buildTopBar(l10n),
                const SizedBox(height: 20),
                if (_periods.isNotEmpty) _buildPeriodTabs(),
                const SizedBox(height: 24),
                if (state is PaymentLoading && _allPlans.isEmpty)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: _accent),
                    ),
                  )
                else if (state is PaymentError && _allPlans.isEmpty)
                  Expanded(
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
                            style: FilledButton.styleFrom(
                                backgroundColor: _accent),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(child: _buildCardsSection(l10n)),
                _buildFooterNote(l10n),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Spacer(),
          Text(
            l10n.plansTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? const Color(0xFF0D0D1A) : Colors.white60,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _PlanCard(
                plan: plan,
                isCurrent: isCurrent,
                storageLabel: _formatStorage(plan.storage),
                priceFormatted: _formatPrice(plan.price),
                onPurchase: isCurrent ? null : () => _purchase(plan),
              ),
            );
          },
        ),
        if (_currentPage > 0)
          Positioned(
            left: 4,
            child: _NavArrow(
              icon: Icons.chevron_left,
              onTap: _prev,
            ),
          ),
        if (_currentPage < _filteredPlans.length - 1)
          Positioned(
            right: 4,
            child: _NavArrow(
              icon: Icons.chevron_right,
              onTap: _next,
            ),
          ),
      ],
    );
  }

  Widget _buildFooterNote(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 14, color: Colors.white38),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n.dataPreservedNote,
              style: const TextStyle(fontSize: 12, color: Colors.white38),
            ),
          ),
        ],
      ),
    );
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final bool isCurrent;
  final String storageLabel;
  final String priceFormatted;
  final VoidCallback? onPurchase;

  static const _green = Color(0xFF22C55E);
  static const _accent = Color(0xFF3B82F6);
  static const _cardBg = Color(0xFF161626);

  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.storageLabel,
    required this.priceFormatted,
    this.onPurchase,
  });

  Color get _borderColor =>
      isCurrent ? _green : const Color(0xFF2A2A40);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFree =
        plan.price == '0' || plan.price == '0.00' || plan.price.startsWith('0.');

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor,
          width: isCurrent ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBadge(isCurrent, l10n),
          const SizedBox(height: 12),
          Text(
            storageLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: isFree
                      ? '0.00 UZS / '
                      : '$priceFormatted UZS / ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: isFree ? l10n.freeLabel : '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (!isFree)
            Text(
              plan.billingPeriod,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF2A2A40), height: 1),
          const SizedBox(height: 12),
          ...plan.items
              .where((item) => item.isAvailable)
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: _green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.feature,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
          if (plan.items.isEmpty)
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: _green, size: 16),
                const SizedBox(width: 8),
                Text(
                  l10n.storageFeature(storageLabel),
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          const Spacer(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: isCurrent
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _green),
                      foregroundColor: _green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      l10n.currentPlan,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )
                : FilledButton(
                    onPressed: onPurchase,
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      l10n.updatePlan,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ],
      ),
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
