import 'dart:ui';
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<IconData> icons = [
      Icons.home_rounded,
      Icons.calendar_month_rounded,
      Icons.chat_bubble_rounded,
      Icons.bar_chart_rounded,
      Icons.nightlight_round,
      Icons.settings_rounded,
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, left: 24.0, right: 24.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(icons.length, (index) {
                  final isSelected = selectedIndex == index;
                  return GestureDetector(
                    onTap: () => onItemTapped(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.05),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                      child: Icon(
                        icons[index],
                        color: isSelected ? Colors.white : Colors.white60,
                        size: isSelected ? 28 : 24,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
