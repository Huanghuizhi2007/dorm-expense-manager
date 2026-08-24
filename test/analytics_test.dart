import 'package:dormbill/core/analytics.dart';
import 'package:dormbill/data/models/expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('analytics', () {
    test('分类汇总金额和百分比正确', () {
      final expenses = <Expense>[
        _expense('e1', 60, '食品', DateTime(2026, 8, 1)),
        _expense('e2', 40, '食品', DateTime(2026, 8, 5)),
        _expense('e3', 50, '日用品', DateTime(2026, 8, 10)),
        _expense('e4', 50, '日用品', DateTime(2026, 9, 1)),
      ];

      final summaries = buildCategorySummaries(
        expenses,
        DateTime(2026, 8, 15),
      );

      expect(summaries, hasLength(2));
      expect(summaries.first.category, '食品');
      expect(summaries.first.amountCents, 10000);
      expect(summaries.first.percent, closeTo(50, 0.001));
      expect(summaries.last.amountCents, 5000);
      expect(summaries.last.percent, closeTo(50, 0.001));
    });

    test('日历标记和当天明细正确', () {
      final expenses = <Expense>[
        _expense('e1', 20, '其他', DateTime(2026, 8, 3)),
        _expense('e2', 15, '其他', DateTime(2026, 8, 3, 18, 30)),
        _expense('e3', 10, '其他', DateTime(2026, 8, 24)),
      ];

      final marked = expenseDaysInMonth(expenses, DateTime(2026, 8, 1));
      expect(marked, <int>{3, 24});

      final dayExpenses = expensesOnDay(
        expenses,
        DateTime(2026, 8, 3),
      );
      expect(dayExpenses, hasLength(2));
    });
  });
}

Expense _expense(String id, double amount, String category, DateTime date) {
  return Expense(
    id: id,
    dormitoryId: 'dorm1',
    title: '测试支出',
    amount: amount,
    category: category,
    payerId: 'u1',
    creatorId: 'u1',
    createdAt: date,
    payerName: '张三',
  );
}

