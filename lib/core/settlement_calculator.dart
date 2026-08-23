import 'app_constants.dart';

import '../data/models/dorm_member.dart';
import '../data/models/expense.dart';

class BalanceLine {
  const BalanceLine({
    required this.userId,
    required this.username,
    required this.paidCents,
    required this.shareCents,
    required this.balanceCents,
  });

  final String userId;
  final String username;
  final int paidCents;
  final int shareCents;
  final int balanceCents;

  double get paid => paidCents / 100;
  double get share => shareCents / 100;
  double get balance => balanceCents / 100;
}

class Transfer {
  const Transfer({
    required this.fromUserId,
    required this.toUserId,
    required this.fromName,
    required this.toName,
    required this.amountCents,
  });

  final String fromUserId;
  final String toUserId;
  final String fromName;
  final String toName;
  final int amountCents;

  double get amount => amountCents / 100;
}

class SettlementResult {
  const SettlementResult({
    required this.totalCents,
    required this.lines,
    required this.transfers,
  });

  final int totalCents;
  final List<BalanceLine> lines;
  final List<Transfer> transfers;

  double get total => totalCents / 100;
  double get average => lines.isEmpty ? 0 : total / lines.length;
}

class _SettlementNode {
  _SettlementNode(this.line) : balanceCents = line.balanceCents;

  final BalanceLine line;
  int balanceCents;
}

class SettlementCalculator {
  static SettlementResult calculate({
    required List<Expense> expenses,
    required List<DormMember> members,
    required DateTime month,
  }) {
    final monthExpenses = expenses
        .where((expense) => sameMonth(expense.createdAt, month))
        .toList();

    final totalCents = monthExpenses.fold<int>(
      0,
      (sum, expense) => sum + (expense.amount * 100).round(),
    );

    final memberCount = members.length;
    final shareBase = memberCount == 0 ? 0 : totalCents ~/ memberCount;
    final remainder = memberCount == 0 ? 0 : totalCents % memberCount;
    final sortedMembers = <DormMember>[...members]
      ..sort((a, b) => a.userId.compareTo(b.userId));

    final lines = <BalanceLine>[];
    for (var index = 0; index < sortedMembers.length; index++) {
      final member = sortedMembers[index];
      final paidCents = monthExpenses
          .where((expense) => expense.payerId == member.userId)
          .fold<int>(0, (sum, expense) => sum + (expense.amount * 100).round());
      final shareCents = shareBase + (index < remainder ? 1 : 0);
      lines.add(
        BalanceLine(
          userId: member.userId,
          username: member.username,
          paidCents: paidCents,
          shareCents: shareCents,
          balanceCents: paidCents - shareCents,
        ),
      );
    }

    final transfers = _buildTransfers(lines);
    return SettlementResult(
      totalCents: totalCents,
      lines: lines,
      transfers: transfers,
    );
  }

  static List<Transfer> _buildTransfers(List<BalanceLine> lines) {
    final creditors = lines
        .where((line) => line.balanceCents > 0)
        .map(_SettlementNode.new)
        .toList()
      ..sort((a, b) => b.balanceCents.compareTo(a.balanceCents));
    final debtors = lines
        .where((line) => line.balanceCents < 0)
        .map(_SettlementNode.new)
        .toList()
      ..sort((a, b) => a.balanceCents.compareTo(b.balanceCents));

    final transfers = <Transfer>[];
    var debtorIndex = 0;
    var creditorIndex = 0;

    while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
      final debtor = debtors[debtorIndex];
      final creditor = creditors[creditorIndex];
      final owed = -debtor.balanceCents;
      final credit = creditor.balanceCents;
      final amountCents = owed < credit ? owed : credit;

      if (amountCents > 0) {
        transfers.add(
          Transfer(
            fromUserId: debtor.line.userId,
            toUserId: creditor.line.userId,
            fromName: debtor.line.username,
            toName: creditor.line.username,
            amountCents: amountCents,
          ),
        );
      }

      debtor.balanceCents += amountCents;
      creditor.balanceCents -= amountCents;

      if (debtor.balanceCents == 0) debtorIndex++;
      if (creditor.balanceCents == 0) creditorIndex++;
    }

    return transfers;
  }
}
