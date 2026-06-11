import 'package:flutter/material.dart';
import 'package:my_diet/data/methodology_registry.dart';
import 'package:my_diet/services/appmetrica_service.dart';
import 'package:my_diet/services/profile_service.dart';
import 'package:my_diet/services/purchase_verification_service.dart';
import 'package:my_diet/screens/diary_screen.dart';
import 'package:my_diet/screens/express_methodology_screen.dart';
import 'package:my_diet/screens/fun_methodology_screen.dart';
import 'package:my_diet/screens/men_methodology_screen.dart';
import 'package:my_diet/screens/victory_methodology_screen.dart';
import 'package:my_diet/screens/gourmet_methodology_screen.dart';
import 'package:my_diet/screens/methodologies_screen.dart';
import 'package:my_diet/screens/profile_screen.dart';
import 'package:my_diet/screens/progress_screen.dart';
import 'package:my_diet/screens/settings_screen.dart';
import 'package:my_diet/widgets/common_widgets.dart';

/// Оболочка приложения — нижняя навигация и вкладки
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _selectedIndex = 0;
  var _methodologyView = 0; // 0 — список … 5 — victory

  final _progressKey = GlobalKey<ProgressScreenState>();
  final _diaryKey = GlobalKey<DiaryScreenState>();
  final _profileKey = GlobalKey<ProfileScreenState>();

  void _onDiaryWeightChanged() {
    _profileKey.currentState?.refresh();
    _progressKey.currentState?.refresh();
  }

  void _openMethodologiesHub() {
    setState(() {
      _selectedIndex = 0;
      _methodologyView = 0;
    });
  }

  Future<void> _openMethodology(int viewIndex, String methodologyId) async {
    await ProfileService.setActiveMethodology(methodologyId);
    await AppMetricaService.reportMethodologyOpened(methodologyId);
    if (!mounted) return;
    setState(() => _methodologyView = viewIndex);
    _diaryKey.currentState?.refresh();
    _progressKey.currentState?.refresh();
    // Проверка оплаты в фоне — не блокирует переключение экрана.
    PurchaseVerificationService.verifyBeforeAccess(methodologyId);
  }

  void _handleSystemBack() {
    if (_methodologyView != 0) {
      setState(() => _methodologyView = 0);
      return;
    }
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleSystemBack();
      },
      child: Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          IndexedStack(
            index: _methodologyView,
            children: [
              MethodologiesScreen(
                showBackButton: false,
                onOpenExpress: () => _openMethodology(1, MethodologyIds.express),
                onOpenGourmets: () => _openMethodology(2, MethodologyIds.gourmets),
                onOpenFun: () => _openMethodology(3, MethodologyIds.fun),
                onOpenMen: () => _openMethodology(4, MethodologyIds.men),
                onOpenVictory: () => _openMethodology(5, MethodologyIds.victory),
              ),
              ExpressMethodologyScreen(
                isActiveView: _selectedIndex == 0 && _methodologyView == 1,
                onBack: () => setState(() => _methodologyView = 0),
              ),
              GourmetMethodologyScreen(
                isActiveView: _selectedIndex == 0 && _methodologyView == 2,
                onBack: () => setState(() => _methodologyView = 0),
              ),
              FunMethodologyScreen(
                isActiveView: _selectedIndex == 0 && _methodologyView == 3,
                onBack: () => setState(() => _methodologyView = 0),
              ),
              MenMethodologyScreen(
                isActiveView: _selectedIndex == 0 && _methodologyView == 4,
                onBack: () => setState(() => _methodologyView = 0),
              ),
              VictoryMethodologyScreen(
                isActiveView: _selectedIndex == 0 && _methodologyView == 5,
                onBack: () => setState(() => _methodologyView = 0),
              ),
            ],
          ),
          DiaryScreen(key: _diaryKey, onWeightChanged: _onDiaryWeightChanged),
          ProgressScreen(key: _progressKey),
          ProfileScreen(
            key: _profileKey,
            onOpenMethodologies: _openMethodologiesHub,
          ),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: StyledBottomNav(
        currentIndex: _selectedIndex,
        onTap: (i) {
          const tabNames = [
            'methodologies',
            'diary',
            'progress',
            'profile',
            'settings',
          ];
          AppMetricaService.reportTabSelected(tabNames[i]);
          setState(() => _selectedIndex = i);
          if (i == 1) _diaryKey.currentState?.refresh();
          if (i == 2) _progressKey.currentState?.refresh();
          if (i == 3) _profileKey.currentState?.refresh();
        },
      ),
    ),
    );
  }
}
