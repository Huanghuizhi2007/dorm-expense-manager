import 'package:dormbill/core/settlement_calculator.dart';
import 'package:dormbill/data/models/dorm_member.dart';
import 'package:dormbill/data/models/expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettlementCalculator', () {
    test('按示例自动计算每人承担和最少转账', () {
      final members = <DormMember>[
        _member('u1', '张三'),
        _member('u2', '李四'),
        _member('u3', '王五'),
        _member('u4', '赵六'),
      ];
      final expenses = <Expense>[
        _expense('e1', '公共用品', 400, 'u1'),
        _expense('e2', '日常开销', 100, 'u2'),
        _expense('e3', '零食饮料', 60, 'u3'),
      ];

      final result = SettlementCalculator.calculate(
        expenses: expenses,
        members: members,
        month: DateTime(2026, 8, 15),
      );

      expect(result.totalCents, 56000);
      expect(result.average, 140);
      expect(result.lines, hasLength(4));

      final byName = {
        for (final line in result.lines) line.username: line,
      };
      expect(byName['张三']!.paidCents, 40000);
      expect(byName['张三']!.shareCents, 14000);
      expect(byName['张三']!.balanceCents, 26000);

      expect(byName['李四']!.balanceCents, -4000);
      expect(byName['王五']!.balanceCents, -8000);
      expect(byName['赵六']!.balanceCents, -14000);

      expect(
        result.transfers
            .map(
              (transfer) =>
                  '${transfer.fromName}->${transfer.toName}:${transfer.amountCents}',
            )
            .toList(),
        <String>['李四->张三:4000', '王五->张三:8000', '赵六->张三:14000'],
      );
    });

    test('没有支出时结算为零', () {
      final result = SettlementCalculator.calculate(
        expenses: <Expense>[],
        members: <DormMember>[_member('u1', '张三')],
        month: DateTime(2026, 8, 1),
      );

      expect(result.totalCents, 0);
      expect(result.transfers, isEmpty);
      expect(result.lines.single.balanceCents, 0);
    });
  });
}

DormMember _member(String id, String username) {
  return DormMember(
    id: 'member_$id',
    dormitoryId: 'dorm1',
    userId: id,
    username: username,
    role: 'member',
    joinedAt: DateTime(2026, 8, 1),
  );
}

Expense _expense(String id, String title, double amount, String payerId) {
  return Expense(
    id: id,
    dormitoryId: 'dorm1',
    title: title,
    amount: amount,
    category: '其他',
    payerId: payerId,
    creatorId: payerId,
    createdAt: DateTime(2026, 8, 3),
    payerName: payerId,
  );
}

