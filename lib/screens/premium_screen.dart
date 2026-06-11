import 'package:flutter/material.dart';
import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/services/payment_flow_service.dart';
import 'package:my_diet/services/premium_purchase_service.dart';
import 'package:my_diet/services/theme_provider.dart';
import 'package:my_diet/widgets/common_widgets.dart';

/// Экран покупки ПРЕМИУМ — открытие всех дней каждой методики.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _allPurchased = false;
  static const _products = <_PremiumProduct>[
    _PremiumProduct(
      methodologyId: MethodologyIds.express,
      title: 'Открыть все этапы Диеты быстрой',
    ),
    _PremiumProduct(
      methodologyId: MethodologyIds.gourmets,
      title: 'Открыть все этапы Диеты вкусной',
    ),
    _PremiumProduct(
      methodologyId: MethodologyIds.fun,
      title: 'Открыть все этапы Диеты интересной',
    ),
    _PremiumProduct(
      methodologyId: MethodologyIds.men,
      title: 'Открыть все этапы Диеты мужской',
    ),
    _PremiumProduct(
      methodologyId: MethodologyIds.victory,
      title: 'Открыть все этапы Диеты трудной',
    ),
  ];

  Set<String> _purchasedIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPurchased();
  }

  Future<void> _loadPurchased() async {
    final ids = await PremiumPurchaseService.loadPurchasedIds();
    final all = await PremiumPurchaseService.isAllPurchased();
    if (mounted) {
      setState(() {
        _purchasedIds = ids;
        _allPurchased = all;
        _loading = false;
      });
    }
  }

  Future<void> _onBuyAllTap() async {
    if (_allPurchased) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Все диеты уже открыты')),
      );
      return;
    }

    final paid = await PaymentFlowService.payForAllMethodologiesPremium(
      context: context,
    );

    if (!paid || !mounted) return;

    await _loadPurchased();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Все диеты открыты! Все этапы и дни доступны.'),
      ),
    );
  }

  Future<void> _onBuyTap(_PremiumProduct product) async {
    if (_purchasedIds.contains(product.methodologyId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Эта диета уже открыта')),
      );
      return;
    }

    final paid = await PaymentFlowService.payForMethodologyPremium(
      context: context,
      methodologyId: product.methodologyId,
    );

    if (!paid || !mounted) return;

    final title = MethodologyRegistry.get(product.methodologyId).title;
    await _loadPurchased();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '«$title» открыта! Все этапы и дни доступны.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppGradientBackground(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 16,
                left: 4,
                right: 20,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'ПРЕМИУМ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Откройте все дни выбранной диеты без ограничений',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.brown.shade800
                                    .withValues(alpha: 0.85),
                                height: 1.35,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._products.map(
                            (product) => _PremiumButton(
                              title: product.title,
                              price: PremiumPurchaseService.methodologyPriceRub,
                              isPurchased: _purchasedIds
                                  .contains(product.methodologyId),
                              onTap: () => _onBuyTap(product),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _PremiumButton(
                            title: 'Открыть все диеты',
                            price: PremiumPurchaseService.allMethodologiesPriceRub,
                            isPurchased: _allPurchased,
                            highlighted: true,
                            onTap: _onBuyAllTap,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumProduct {
  final String methodologyId;
  final String title;

  const _PremiumProduct({
    required this.methodologyId,
    required this.title,
  });
}

class _PremiumButton extends StatelessWidget {
  final String title;
  final int price;
  final bool isPurchased;
  final bool highlighted;
  final VoidCallback onTap;

  const _PremiumButton({
    required this.title,
    required this.price,
    required this.isPurchased,
    this.highlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2A27) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: highlighted && !isPurchased
              ? Border.all(color: ThemeProvider.primaryGreen, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9800).withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(
            isPurchased ? Icons.check_circle : Icons.workspace_premium,
            color: isPurchased ? Colors.green : ThemeProvider.primaryGreen,
            size: 24,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              height: 1.3,
              color: isPurchased ? Colors.grey.shade600 : null,
            ),
          ),
          trailing: isPurchased
              ? const Text(
                  'Куплено',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.green,
                  ),
                )
              : Text(
                  '$price р',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: ThemeProvider.primaryGreen,
                  ),
                ),
        ),
      ),
    );
  }
}
