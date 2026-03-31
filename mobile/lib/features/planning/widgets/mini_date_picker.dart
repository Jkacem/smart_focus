import 'package:flutter/material.dart';

class MiniDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  const MiniDatePicker({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onPreviousWeek,
    required this.onNextWeek,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final weekDays = _buildWeekDays(selectedDate);
    final today = DateTime.now();
    final monthLabel = _monthLabel(selectedDate);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: Colors.white70,
                size: 20,
              ),
              onPressed: onPreviousWeek,
            ),
            Text(
              monthLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.chevron_right,
                color: Colors.white70,
                size: 20,
              ),
              onPressed: onNextWeek,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays.map((day) {
            final isSelected = _isSameDay(day, selectedDate);
            final isToday = _isSameDay(day, today);

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onDateSelected(day),
              child: Column(
                children: [
                  Text(
                    _dayLabel(day),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.24)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white70
                            : (isToday ? Colors.white38 : Colors.transparent),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      day.day.toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<DateTime> _buildWeekDays(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final startOfWeek = normalized.subtract(Duration(days: normalized.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  String _monthLabel(DateTime date) {
    const months = [
      'Janvier',
      'Fevrier',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Aout',
      'Septembre',
      'Octobre',
      'Novembre',
      'Decembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _dayLabel(DateTime date) {
    const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return labels[date.weekday - 1];
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
