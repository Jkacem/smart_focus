import 'package:flutter/material.dart';

/// A customizable button widget used throughout the app.
/// Provides consistent styling with support for different themes and sizes.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double borderRadius;
  final Widget? leadingWidget;
  final EdgeInsets? padding;
  final List<BoxShadow>? boxShadow;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height,
    this.backgroundColor = const Color(0xFF97cad8),
    this.borderColor = const Color.fromARGB(88, 0, 0, 0),
    this.textColor = const Color.fromRGBO(0, 0, 0, 0.56),
    this.fontSize = 20,
    this.fontWeight = FontWeight.w600,
    this.borderRadius = 25,
    this.leadingWidget,
    this.padding,
    this.boxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.25),
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: const Color.fromARGB(22, 0, 0, 0),
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: leadingWidget != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      leadingWidget!,
                      const SizedBox(width: 12),
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: fontWeight,
                          color: textColor,
                          fontFamily: 'SF Pro',
                        ),
                      ),
                    ],
                  )
                : Text(
                    text,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: fontWeight,
                      color: textColor,
                      fontFamily: 'SF Pro',
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
