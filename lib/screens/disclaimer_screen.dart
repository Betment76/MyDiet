import 'package:flutter/material.dart';
import 'package:my_diet/data/legal_documents.dart';
import 'package:my_diet/services/disclaimer_service.dart';
import 'package:my_diet/services/profile_service.dart';
import 'package:my_diet/services/theme_provider.dart';

/// Экран дисклеймера — показывается перед использованием приложения.
class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  static const _sidePadding = 8.0;

  bool _accepted = false;
  bool _pdConsentAccepted = false;
  bool _saving = false;

  bool get _canContinue => _accepted && _pdConsentAccepted && !_saving;

  Future<void> _continue() async {
    if (!_canContinue) return;

    setState(() => _saving = true);
    await DisclaimerService.accept();

    if (!mounted) return;

    final profileExists = await ProfileService.exists();
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      profileExists ? '/home' : '/onboarding',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8BBD0),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD32F2F),
              Color(0xFFEF9A9A),
              Color(0xFFF8BBD0),
            ],
            stops: [0.0, 0.38, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Важная информация',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Пожалуйста, внимательно прочитайте перед использованием приложения.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _DisclaimerBlock(
                            title: 'Информационный характер',
                            text:
                                'Все материалы приложения носят исключительно '
                                'информационный характер и не являются медицинскими '
                                'рекомендациями, назначениями или руководством к лечению.',
                          ),
                          const SizedBox(height: 12),
                          const _DisclaimerBlock(
                            title: 'Консультация врача',
                            text:
                                'Перед началом следования любой диете или методике '
                                'похудения, представленной в приложении, необходима '
                                'обязательная консультация с квалифицированным '
                                'врачом-диетологом или другим лечащим врачом.',
                          ),
                          const SizedBox(height: 12),
                          const _DisclaimerBlock(
                            title: 'Ответственность',
                            text:
                                'Разработчики приложения не несут ответственности '
                                'за любые последствия, связанные с самостоятельным '
                                'использованием описанных в приложении методов, '
                                'диет, рекомендаций и материалов, включая ухудшение '
                                'состояния здоровья.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  _sidePadding,
                  2,
                  _sidePadding,
                  2 + bottomInset,
                ),
                child: Column(
                  children: [
                    _DisclaimerCheckboxCard(
                      compact: true,
                      value: _accepted,
                      onChanged: (value) =>
                          setState(() => _accepted = value ?? false),
                      child: Text(
                        'Я прочитал(а) информацию, понимаю возможные '
                        'риски и принимаю условия использования приложения',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    _DisclaimerCheckboxCard(
                      compact: true,
                      value: _pdConsentAccepted,
                      onChanged: (value) => setState(
                        () => _pdConsentAccepted = value ?? false,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Я даю согласие на обработку персональных данных.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          _DocumentLinksBar(
                            links: [
                              _DocumentLinkItem(
                                label: 'Политика',
                                onTap: () => showLegalDocument(
                                  context,
                                  title: LegalDocuments.privacyPolicyTitle,
                                  body: LegalDocuments.privacyPolicyBody,
                                ),
                              ),
                              _DocumentLinkItem(
                                label: 'Согласие',
                                onTap: () => showLegalDocument(
                                  context,
                                  title: LegalDocuments.consentPdTitle,
                                  body: LegalDocuments.consentPdBody,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _canContinue ? _continue : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: ThemeProvider.primaryGreen,
                          disabledBackgroundColor: Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.grey.shade700,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Продолжить',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisclaimerCheckboxCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final Widget child;
  final bool compact;

  const _DisclaimerCheckboxCard({
    required this.value,
    required this.onChanged,
    required this.child,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 4 : 10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Checkbox(
                value: value,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                activeColor: ThemeProvider.primaryGreen,
                onChanged: onChanged,
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _DocumentLinkItem {
  final String label;
  final VoidCallback onTap;

  const _DocumentLinkItem({
    required this.label,
    required this.onTap,
  });
}

class _DocumentLinksBar extends StatelessWidget {
  final List<_DocumentLinkItem> links;

  const _DocumentLinksBar({required this.links});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = Colors.grey.shade400;
    final style = theme.textTheme.bodySmall?.copyWith(
      fontSize: 12,
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.2,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < links.length; i++) ...[
              if (i > 0) VerticalDivider(width: 1, thickness: 1, color: borderColor),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: links[i].onTap,
                    borderRadius: BorderRadius.horizontal(
                      left: i == 0 ? const Radius.circular(5) : Radius.zero,
                      right: i == links.length - 1
                          ? const Radius.circular(5)
                          : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        links[i].label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DisclaimerBlock extends StatelessWidget {
  final String title;
  final String text;

  const _DisclaimerBlock({
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          textAlign: TextAlign.justify,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.35,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
