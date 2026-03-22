import 'package:flutter/material.dart';

/// Displays the robot illustration on the welcome screen.
class RobotSection extends StatelessWidget {
  const RobotSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 350,
          height: 350,
          child: Image.asset('assets/images/image.png'),
        ),
      ],
    );
  }
}
