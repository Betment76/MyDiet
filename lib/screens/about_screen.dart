import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_diet/constants/app_version.dart';
import 'package:my_diet/data/legal_documents.dart';
import 'package:my_diet/screens/literature_screen.dart';
import 'package:my_diet/services/export_service.dart';
import 'package:my_diet/services/rustore_review_service.dart';
import 'package:my_diet/services/theme_provider.dart';
import 'package:my_diet/widgets/common_widgets.dart';

/// Экран «О приложении»
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
                    'О приложении',
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Название + версия
                  const Text(
                    'Моя диета',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppVersion.display,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),

                  const SizedBox(height: 8),

                  // Юридические документы
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Container(
                      width: double.infinity,
                      decoration: _cardDecoration(context),
                      child: ExpansionTile(
                        leading: const Icon(Icons.gavel_outlined, color: ThemeProvider.primaryGreen, size: 22),
                        title: const Text('Юридические документы', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        children: [
                          _DocTile(
                            title: LegalDocuments.privacyPolicyTitle,
                            onTap: () => showLegalDocument(
                              context,
                              title: LegalDocuments.privacyPolicyTitle,
                              body: LegalDocuments.privacyPolicyBody,
                            ),
                          ),
                          _DocTile(
                            title: LegalDocuments.userAgreementTitle,
                            onTap: () => showLegalDocument(
                              context,
                              title: LegalDocuments.userAgreementTitle,
                              body: LegalDocuments.userAgreementBody,
                            ),
                          ),
                          _DocTile(
                            title: LegalDocuments.publicOfferTitle,
                            onTap: () => showLegalDocument(
                              context,
                              title: LegalDocuments.publicOfferTitle,
                              body: LegalDocuments.publicOfferBody,
                            ),
                          ),
                          _DocTile(
                            title: 'Согласие на обработку ПД',
                            onTap: () => showLegalDocument(
                              context,
                              title: LegalDocuments.consentPdTitle,
                              body: LegalDocuments.consentPdBody,
                            ),
                          ),
                          _DocTile(
                            title: LegalDocuments.disclaimerLegalTitle,
                            onTap: () => showLegalDocument(
                              context,
                              title: LegalDocuments.disclaimerLegalTitle,
                              body: LegalDocuments.disclaimerLegalBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Инструкция по использованию
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Container(
                      width: double.infinity,
                      decoration: _cardDecoration(context),
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(Icons.menu_book_outlined, color: ThemeProvider.primaryGreen, size: 22),
                        title: const Text('Инструкция по использованию', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () => _showBottomSheet(context, 'Инструкция по использованию', _instruction),
                      ),
                    ),
                  ),

                  // Список используемой литературы
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Container(
                      width: double.infinity,
                      decoration: _cardDecoration(context),
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(Icons.auto_stories_outlined, color: ThemeProvider.primaryGreen, size: 22),
                        title: const Text('Список используемой литературы', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () { Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LiteratureScreen())); },
                      ),
                    ),
                  ),

                  // Что нового в версии
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Container(
                      width: double.infinity,
                      decoration: _cardDecoration(context),
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(Icons.new_releases_outlined, color: ThemeProvider.primaryGreen, size: 22),
                        title: Text(AppVersion.whatsNewTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () => _showBottomSheet(context, AppVersion.whatsNewTitle, _whatsNew),
                      ),
                    ),
                  ),

                  // Отблагодарить разработчика
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Container(
                      width: double.infinity,
                      decoration: _cardDecoration(context),
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(Icons.favorite_outline, color: ThemeProvider.primaryGreen, size: 22),
                        title: const Text('Отблагодарить разработчика', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () => _showThanksSheet(context),
                      ),
                    ),
                  ),

                  // Написать разработчику
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Container(
                      width: double.infinity,
                      decoration: _cardDecoration(context),
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(Icons.mail_outline, color: ThemeProvider.primaryGreen, size: 22),
                        title: const Text('Написать разработчику', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('support@мойсофт.рф', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {
                          Clipboard.setData(
                            const ClipboardData(text: 'support@мойсофт.рф'),
                          );
                        },
                      ),
                    ),
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

  BoxDecoration _cardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E2A27) : const Color(0xFFFAFAFA),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFFF9800).withValues(alpha: 0.25),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  void _showBottomSheet(BuildContext context, String title, String body) {
    showAppBottomSheet<void>(
      context: context,
      title: title,
      body: body,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: ThemeProvider.primaryGreen,
          ),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }

  void _showThanksSheet(BuildContext context) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Спасибо!',
      body: _thanks,
      actions: [
        FilledButton.icon(
          onPressed: () async {
            final outcome = await RustoreReviewService.requestReview();
            if (!context.mounted || outcome.hint == null) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(outcome.hint!)),
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor: ThemeProvider.primaryGreen,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.rate_review_outlined, size: 20),
          label: const Text('Оставить отзыв в RuStore'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => ExportService.shareApp(),
          icon: const Icon(Icons.share_outlined, size: 20),
          label: const Text('Поделиться приложением'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => ExportService.shareCurrentProgress(),
          icon: const Icon(Icons.emoji_events_outlined, size: 20),
          label: const Text('Поделиться результатом'),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}

/// Строка внутри юридических документов
class _DocTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _DocTile({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const SizedBox(width: 40),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}

const _instruction = '''
ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ

1. ПЕРВЫЙ ЗАПУСК
При первом запуске заполните анкету: укажите имя, рост, текущий и целевой вес, дату рождения. При желании можно указать электронную почту для получения чеков при оплате. Эти данные нужны для расчёта ИМТ и индивидуальных рекомендаций.

2. ВЫБОР МЕТОДИКИ
В приложении доступно 5 методик похудения:
— Диета быстрая
— Диета вкусная
— Диета интересная
— Диета мужская
— Диета трудная
Выберите подходящую на главном экране.

3. ПЛАН ПИТАНИЯ
Каждая методика состоит из 3 этапов. Для каждого этапа формируется меню на каждый день. Отмечайте выполненные приёмы пищи в дневнике.

4. ЗАПРЕЩЁННЫЕ ПРОДУКТЫ
В настройках профиля можно отметить продукты, которые нужно исключить из меню (аллергия, непереносимость). Меню будет автоматически скорректировано.

5. ДНЕВНИК
В дневнике ведите учёт:
— Выполненных приёмов пищи;
— Выпитой воды (норма: 30 мл на 1 кг веса);
— Прогулок (цель: 60 минут в день).

6. ПРОГРЕСС
На вкладке «Прогресс» отслеживайте:
— График изменения веса;
— Процент выполнения этапа;
— Общую статистику.

7. НАСТРОЙКИ
В настройках можно:
— Настроить напоминания о воде;
— Создать/восстановить резервную копию.
''';

const _whatsNew = '''
ЧТО НОВОГО В ВЕРСИИ 1.0.1

• Подготовка к публикации в RuStore
• Оплата этапов и ПРЕМИУМ через T‑Банк (СБП / карта)
• In-app отзывы RuStore
• Юридические документы и дисклеймер при первом запуске
• Улучшения стабильности и интерфейса

Спасибо, что выбрали наше приложение!
''';

const _thanks = '''
Спасибо, что пользуетесь приложением «Моя диета»!

Ваша поддержка очень важна для нас. Если приложение оказалось полезным, оставьте отзыв, порекомендуйте его друзьям или поделитесь своим прогрессом.

Мы продолжаем работать над улучшением приложения и будем рады любым предложениям и замечаниям.

С уважением,
команда МойСофт
support@мойсофт.рф
''';
