import 'package:flutter/material.dart';

class ConfigRangeLabels extends StatelessWidget {
  final String min;
  final String max;

  const ConfigRangeLabels({super.key, required this.min, required this.max});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context)
              .textTheme
              .bodySmall
              ?.color
              ?.withValues(alpha: 0.5),
          fontSize: 11,
        );
    return Padding(
      padding: const EdgeInsets.only(left: 26, top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(min, style: style),
          Text(max, style: style),
        ],
      ),
    );
  }
}
