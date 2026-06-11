import 'package:flutter/material.dart';

/// Описание методики на главном экране
class MethodologyInfo {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final Color accentColor;
  final bool available;

  const MethodologyInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.accentColor,
    this.available = false,
  });
}

/// Список методик приложения
class MethodologiesData {
  static const items = [
    MethodologyInfo(
      id: 'express',
      title: 'Диета быстрая',
      subtitle: 'Поэтапное похудения для здоровых людей.',
      emoji: '⚡',
      accentColor: Color(0xFF2E7D32),
      available: true,
    ),
    MethodologyInfo(
      id: 'gourmets',
      title: 'Диета вкусная',
      subtitle: 'Вкусно и без строгих ограничений',
      emoji: '🍽️',
      accentColor: Color(0xFFE65100),
      available: true,
    ),
    MethodologyInfo(
      id: 'fun',
      title: 'Диета интересная',
      subtitle: 'Игровой подход к снижению веса',
      emoji: '🎮',
      accentColor: Color(0xFF7B1FA2),
      available: true,
    ),
    MethodologyInfo(
      id: 'men',
      title: 'Диета мужская',
      subtitle: 'Программа с учётом мужского метаболизма',
      emoji: '💪',
      accentColor: Color(0xFF1565C0),
      available: true,
    ),
    MethodologyInfo(
      id: 'victory',
      title: 'Диета трудная',
      subtitle: 'Долгосрочная стратегия закрепления результата',
      emoji: '🏆',
      accentColor: Color(0xFFC62828),
      available: true,
    ),
  ];
}
