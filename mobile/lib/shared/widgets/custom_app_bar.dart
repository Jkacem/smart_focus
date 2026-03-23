import 'dart:ui';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData trailingIcon;
  final VoidCallback? onTrailingPressed;
  final Widget? trailingWidget;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingPressed;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.trailingIcon = Icons.add_a_photo,
    this.onTrailingPressed,
    this.trailingWidget,
    this.leadingIcon,
    this.onLeadingPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  // Center Title
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Left/Leading Icon
                  if (leadingIcon != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(leadingIcon, color: Colors.white),
                        onPressed: onLeadingPressed,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  // Right/Trailing Icon
                  Align(
                    alignment: Alignment.centerRight,
                    child: trailingWidget ??
                        IconButton(
                          icon: Icon(trailingIcon, color: Colors.white),
                          onPressed: onTrailingPressed,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  @override
  Size get preferredSize => const Size.fromHeight(80.0);
}
