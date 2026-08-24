import 'package:flutter/material.dart';

const List<String> expenseCategories = <String>[
  '食品',
  '日用品',
  '电费',
  '水费',
  '网络费',
  '维修费',
  '其他',
];

class CategoryStyle {
  const CategoryStyle({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

const List<CategoryStyle> categoryStyles = <CategoryStyle>[
  CategoryStyle(label: '食品', icon: Icons.restaurant_rounded, color: Color(0xFFE07A5F)),
  CategoryStyle(label: '日用品', icon: Icons.shopping_basket_rounded, color: Color(0xFF7A9E9F)),
  CategoryStyle(label: '电费', icon: Icons.bolt_rounded, color: Color(0xFFF2A33C)),
  CategoryStyle(label: '水费', icon: Icons.water_drop_rounded, color: Color(0xFF4A90D9)),
  CategoryStyle(label: '网络费', icon: Icons.wifi_rounded, color: Color(0xFF6B7FD7)),
  CategoryStyle(label: '维修费', icon: Icons.build_rounded, color: Color(0xFF8D6E63)),
  CategoryStyle(label: '其他', icon: Icons.more_horiz_rounded, color: Color(0xFF94A3B8)),
];

const List<Color> avatarPalette = <Color>[
  Color(0xFF0E7C6B),
  Color(0xFF4A90D9),
  Color(0xFFE07A5F),
  Color(0xFF6B7FD7),
  Color(0xFF7A9E9F),
  Color(0xFFF2A33C),
  Color(0xFFB05FA8),
  Color(0xFF5B8C5A),
];

CategoryStyle categoryStyle(String category) {
  for (final style in categoryStyles) {
    if (style.label == category) return style;
  }
  return categoryStyles.last;
}

Color avatarColorFor(String seed) {
  if (seed.isEmpty) return avatarPalette.first;
  var hash = 0;
  for (final code in seed.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return avatarPalette[hash % avatarPalette.length];
}

String money(num value) => '¥${value.toStringAsFixed(2)}';

String monthKey(DateTime month) =>
    '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';

String monthLabel(DateTime month) => '${month.year}年${month.month}月';

String shortDate(DateTime date) => '${date.month}月${date.day}日';

String fullDate(DateTime date) =>
    '${date.year}年${date.month}月${date.day}日';

bool sameMonth(DateTime date, DateTime month) =>
    date.year == month.year && date.month == month.month;

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String formatPercent(double value) {
  final text = value.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

String initials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  if (trimmed.length <= 2) return trimmed;
  return trimmed.substring(0, 2);
}
