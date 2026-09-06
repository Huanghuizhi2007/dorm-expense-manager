import 'package:dormbill/core/chore_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChoreCalculator', () {
    test('每 3 天从开始日期循环生成', () {
      final assignments = buildChoreAssignments(
        memberOrder: <String>['a', 'b', 'c', 'd'],
        intervalDays: 3,
        startDate: DateTime(2026, 9, 1),
        until: DateTime(2026, 9, 15),
      );

      expect(
        assignments.map((item) => '${item.memberId}:${_key(item.date)}'),
        <String>[
          'a:2026-09-01',
          'b:2026-09-04',
          'c:2026-09-07',
          'd:2026-09-10',
          'a:2026-09-13',
        ],
      );
    });

    test('从今天生成时跳过已过去日期', () {
      final assignments = buildChoreAssignments(
        memberOrder: <String>['a', 'b', 'c', 'd'],
        intervalDays: 3,
        startDate: DateTime(2026, 9, 1),
        from: DateTime(2026, 9, 6),
        until: DateTime(2026, 9, 13),
      );

      expect(
        assignments.map((item) => '${item.memberId}:${_key(item.date)}'),
        <String>[
          'c:2026-09-07',
          'd:2026-09-10',
          'a:2026-09-13',
        ],
      );
    });

    test('每天值日按顺序轮换', () {
      final assignments = buildChoreAssignments(
        memberOrder: <String>['a', 'b'],
        intervalDays: 1,
        startDate: DateTime(2026, 9, 1),
        until: DateTime(2026, 9, 5),
      );

      expect(
        assignments.map((item) => '${item.memberId}:${_key(item.date)}'),
        <String>[
          'a:2026-09-01',
          'b:2026-09-02',
          'a:2026-09-03',
          'b:2026-09-04',
          'a:2026-09-05',
        ],
      );
    });
  });
}

String _key(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
