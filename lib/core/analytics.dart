import '../data/models/expense.dart';
import 'app_constants.dart';

class CategorySummary {
  const CategorySummary({
    required this.category,
    required this.amountCents,
    required this.percent,
  });

  final String category;
  final int amountCents;
  final double percent;

  double get amount => amountCents / 100;
}

List<CategorySummary> buildCategorySummaries(
  List<Expense> expenses,
  DateTime month,
) {
  final monthExpenses = expenses
      .where((expense) => sameMonth(expense.createdAt, month))
      .toList();
  final totals = <String, int>{};
  for (final expense in monthExpenses) {
    final cents = (expense.amount * 100).round();
    totals.update(expense.category, (value) => value + cents,
        ifAbsent: () => cents);
  }

  final totalCents = totals.values.fold<int>(
    0,
    (sum, value) => sum + value,
  );
  final summaries = totals.entries.map((entry) {
    final percent = totalCents == 0
        ? 0.0
        : (entry.value / totalCents) * 100;
    return CategorySummary(
      category: entry.key,
      amountCents: entry.value,
      percent: percent,
    );
  }).toList();
  summaries.sort((a, b) => b.amountCents.compareTo(a.amountCents));
  return summaries;
}

Set<int> expenseDaysInMonth(List<Expense> expenses, DateTime month) {
  return expenses
      .where((expense) => sameMonth(expense.createdAt, month))
      .map((expense) => expense.createdAt.day)
      .toSet();
}

List<Expense> expensesOnDay(List<Expense> expenses, DateTime day) {
  return expenses
      .where((expense) => sameDay(expense.createdAt, day))
      .toList();
}

