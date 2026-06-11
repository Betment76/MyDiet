import 'package:flutter/material.dart';
import 'package:my_diet/constants/ad_constants.dart';
import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/constants/appmetrica_events.dart';
import 'package:my_diet/services/appmetrica_service.dart';
import 'package:my_diet/services/payment_flow_service.dart';
import 'package:my_diet/services/premium_purchase_service.dart';
import 'package:my_diet/services/stage_purchase_service.dart';
import 'package:my_diet/services/stage_unlock_service.dart';
import 'package:my_diet/services/yandex_ads_service.dart';
import 'package:my_diet/services/theme_provider.dart';
import 'package:my_diet/utils/ad_free_notifier.dart';
import 'package:my_diet/widgets/common_widgets.dart';

class UnlockConstants {
  UnlockConstants._();

  static const int stageUnlockPriceRub = StagePurchaseService.stagePriceRub;
  static const int methodologyUnlockPriceRub = PremiumPurchaseService.methodologyPriceRub;
}

Future<void> showStageLockedDialog(
  BuildContext context, {
  required String methodologyId,
  required int stageIndex,
}) {
  final config = MethodologyRegistry.get(methodologyId);
  final prevName = config.stageCardNames[stageIndex - 1];
  final currentName = config.stageCardNames[stageIndex];

  return showAppBottomSheet<void>(
    context: context,
    title: currentName,
    body:
        'Чтобы открыть этап «$currentName», необходимо открыть все дни этапа «$prevName».',
    actions: [
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        style: FilledButton.styleFrom(
          backgroundColor: ThemeProvider.primaryGreen,
        ),
        child: const Text('Понятно'),
      ),
    ],
  );
}

Future<bool> showDayUnlockDialog(
  BuildContext context, {
  required String methodologyId,
  required int stageIndex,
  required int dayNumber,
  required int totalDays,
}) async {
  final config = MethodologyRegistry.get(methodologyId);
  final stageName = config.stageCardNames[stageIndex];
  final dietTitle = config.title;

  await AppMetricaService.reportEventWithMap(
    AppMetricaEvents.dayUnlockDialogShown,
    {
      'methodology_id': methodologyId,
      'stage_index': stageIndex,
      'day_number': dayNumber,
    },
  );

  final result = await showAppBottomSheet<String>(
    context: context,
    title: '$dayNumber-й день',
    child: Text(
      'Чтобы открыть $dayNumber-й день этапа «$stageName», '
      'выберите один из вариантов:',
      style: Theme.of(context).textTheme.bodyMedium,
    ),
    actions: [
      OutlinedButton.icon(
        onPressed: () => Navigator.of(context).pop('ad'),
        icon: const Icon(Icons.play_circle_outline, size: 20),
        label: const Text('Посмотреть рекламу'),
      ),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: () => Navigator.of(context).pop('stage'),
        style: FilledButton.styleFrom(
          backgroundColor: ThemeProvider.primaryGreen,
        ),
        child: Text(
          'Открыть все дни этапа — ${StagePurchaseService.stagePriceRub} р',
        ),
      ),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: () => Navigator.of(context).pop('premium'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFE65100),
        ),
        child: Text(
          'Открыть все этапы диеты — '
          '${PremiumPurchaseService.methodologyPriceRub} р',
        ),
      ),
      const SizedBox(height: 4),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Отмена'),
      ),
    ],
  );

  if (!context.mounted || result == null) return false;

  if (result == 'ad') {
    if (!AdFreeNotifier.value.value) {
      await YandexAdsService().loadAndShowInterstitial(
        adUnitId: AdConstants.interstitialAdUnitId,
      );
    }
    await StageUnlockService.unlockDay(
      methodologyId,
      stageIndex,
      dayNumber,
    );
    await AppMetricaService.reportEventWithMap(
      AppMetricaEvents.dayUnlockedAd,
      {
        'methodology_id': methodologyId,
        'stage_index': stageIndex,
        'day_number': dayNumber,
      },
    );
    return true;
  }

  if (result == 'stage') {
    if (!context.mounted) return false;

    final paid = await PaymentFlowService.payForStageUnlock(
      context: context,
      methodologyId: methodologyId,
      stageIndex: stageIndex,
    );

    if (paid && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Этап «$stageName» открыт! Все $totalDays дней доступны.',
          ),
        ),
      );
    }
    return paid;
  }

  if (result == 'premium') {
    if (!context.mounted) return false;

    final paid = await PaymentFlowService.payForMethodologyPremium(
      context: context,
      methodologyId: methodologyId,
    );

    if (paid && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '«$dietTitle» открыта! Все этапы и дни доступны.',
          ),
        ),
      );
    }
    return paid;
  }

  return false;
}
