import 'package:flutter/material.dart';

class MiniDatePicker extends StatelessWidget {
  const MiniDatePicker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy dates for demonstration
    final List<int> days = [23, 24, 25, 26, 27, 28, 1];
    final List<String> letters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final int todayIndex = 6; // Index for '01'

    return Column(
      children: [
        // Month Header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: Colors.white70,
                size: 20,
              ),
              onPressed: () {},
            ),
            const Text(
              'Mars 2026',
              style: TextStyle(
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
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Days Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final isToday = index == todayIndex;
            return Column(
              children: [
                Text(
                  letters[index],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isToday ? Colors.white.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday
                        ? Border.all(color: Colors.white54, width: 1)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    days[index].toString().padLeft(2, '0'),
                    style: TextStyle(
                      color: isToday ? Colors.white : Colors.white70,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
