import 'package:flutter/material.dart';

/// Модель записи приёма пищи
class MealEntry {
  final DateTime dateTime;
  final MealType type; // завтрак, обед, ужин, перекус
  final String name; // название блюда
  final double calories; // калории
  final double protein; // белки в г
  final double carbs; // углеводы в г
  final double fats; // жиры в г

  MealEntry({
    required this.dateTime,
    required this.type,
    required this.name,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fats = 0,
  });

  Map<String, dynamic> toJson() => {
    'dateTime': dateTime.toIso8601String(),
    'type': type.name,
    'name': name,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fats': fats,
  };

  factory MealEntry.fromJson(Map<String, dynamic> json) => MealEntry(
    dateTime: DateTime.parse(json['dateTime'] as String),
    type: MealType.values.firstWhere((e) => e.name == json['type']),
    name: json['name'] as String,
    calories: (json['calories'] as num).toDouble(),
    protein: (json['protein'] as num).toDouble(),
    carbs: (json['carbs'] as num).toDouble(),
    fats: (json['fats'] as num).toDouble(),
  );
}

enum MealType {
  breakfast('Завтрак', Icons.free_breakfast),
  lunch('Обед', Icons.lunch_dining),
  dinner('Ужин', Icons.dinner_dining),
  snack('Перекус', Icons.cookie);

  final String label;
  final IconData icon;
  const MealType(this.label, this.icon);
}
