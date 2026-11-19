import 'package:flutter/material.dart';

/// Status as a dot plus colored text, so it never relies on color alone.
class StatusLabel extends StatelessWidget {
  final String text;
  final Color color;
  const StatusLabel({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: color, fontWeight: FontWeight.w600);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: style)),
      ],
    );
  }
}
