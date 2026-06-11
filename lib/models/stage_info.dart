import 'package:flutter/material.dart';

/// Информация об этапе методики
class StageInfo {
  final int number;
  final String title;
  final String duration;
  final String description;
  final List<String> allowedFoods; // разрешённые продукты
  final List<String> forbiddenFoods; // запрещённые продукты
  final List<String> tips; // советы
  final IconData icon;

  const StageInfo({
    required this.number,
    required this.title,
    required this.duration,
    required this.description,
    required this.allowedFoods,
    required this.forbiddenFoods,
    required this.tips,
    required this.icon,
  });
}
