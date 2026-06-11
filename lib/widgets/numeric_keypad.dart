import 'package:flutter/material.dart';

class NumericKeypad extends StatelessWidget {
  final void Function(String key) onKeyPress;

  const NumericKeypad({super.key, required this.onKeyPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['.', '0', '⌫'],
    ];

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: rows.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row
                .map((label) =>
                    _KeyButton(label: label, onPress: onKeyPress))
                .toList(),
          );
        }).toList(),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final void Function(String) onPress;

  const _KeyButton({required this.label, required this.onPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDelete = label == '⌫';

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: isDelete
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onPress(label),
            child: Container(
              height: 60,
              alignment: Alignment.center,
              child: isDelete
                  ? Icon(Icons.backspace_outlined,
                      color: theme.colorScheme.error)
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
