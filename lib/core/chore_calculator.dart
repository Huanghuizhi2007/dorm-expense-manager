import '../data/models/chore_task.dart';

class ChoreAssignment {
  const ChoreAssignment({required this.date, required this.memberId});

  final DateTime date;
  final String memberId;
}

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

DateTime addCalendarDays(DateTime date, int days) {
  final base = dateOnly(date);
  return DateTime(base.year, base.month, base.day + days);
}

String choreDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

int daysBetween(DateTime start, DateTime end) =>
    dateOnly(end).difference(dateOnly(start)).inDays;

List<ChoreAssignment> buildChoreAssignments({
  required List<String> memberOrder,
  required int intervalDays,
  required DateTime startDate,
  required DateTime until,
  DateTime? from,
}) {
  if (memberOrder.isEmpty || intervalDays <= 0) return <ChoreAssignment>[];
  final normalizedStart = dateOnly(startDate);
  final normalizedFrom = dateOnly(from ?? normalizedStart);
  final normalizedUntil = dateOnly(until);
  final assignments = <ChoreAssignment>[];

  int firstIndex;
  if (normalizedFrom.isBefore(normalizedStart)) {
    firstIndex = 0;
  } else {
    final diff = daysBetween(normalizedStart, normalizedFrom);
    firstIndex = (diff + intervalDays - 1) ~/ intervalDays;
  }

  for (var index = firstIndex;; index++) {
    final date = addCalendarDays(normalizedStart, intervalDays * index);
    if (date.isAfter(normalizedUntil)) break;
    assignments.add(
      ChoreAssignment(
        date: date,
        memberId: memberOrder[index % memberOrder.length],
      ),
    );
  }
  return assignments;
}

ChoreTask? taskOnDate(List<ChoreTask> tasks, DateTime date) {
  final target = dateOnly(date);
  for (final task in tasks) {
    if (daysBetween(task.taskDate, target) == 0) return task;
  }
  return null;
}

List<ChoreTask> tasksBetween(
  List<ChoreTask> tasks, {
  required DateTime start,
  required DateTime end,
}) {
  final from = dateOnly(start);
  final to = dateOnly(end);
  return tasks
      .where((task) {
        final day = dateOnly(task.taskDate);
        return !day.isBefore(from) && !day.isAfter(to);
      })
      .toList()
    ..sort((a, b) => a.taskDate.compareTo(b.taskDate));
}
