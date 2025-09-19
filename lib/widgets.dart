import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

class ClaimDataSection extends StatelessWidget {
  final String title;
  final Widget child;
  final bool canStretch;
  final IconData? titleIcon;
  final List<Widget>? actions;

  const ClaimDataSection({
    super.key,
    required this.title,
    required this.child,
    this.canStretch = false,
    this.titleIcon,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Card(
      elevation: 01,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: colors.outlineVariant.withAlpha(128)),
      ),
      child: Column(
        mainAxisSize: canStretch ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
            color: colors.surfaceContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (titleIcon != null) ...[
                      Icon(titleIcon,
                          size: 16, color: textStyles.titleSmall?.color),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      title,
                      style: textStyles.titleSmall,
                    ),
                  ],
                ),
                if (actions != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: child,
          ),
        ],
      ),
    );
  }
}

class DataFieldWithCopy extends StatelessWidget {
  final String label;
  final String value;
  const DataFieldWithCopy(
      {super.key, required this.label, required this.value});

  void _copyToClipboard(BuildContext context) {
    final String textToCopy = value.isEmpty ? 'N/A' : value;
    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Copied to clipboard'),
      behavior: SnackBarBehavior.floating,
      width: 200,
      duration: Duration(seconds: 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              const SizedBox(height: 2.0),
              Text(
                value.isEmpty ? 'N/A' : value,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copy to clipboard',
            onPressed: () => _copyToClipboard(context),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class SimpleDataField extends StatelessWidget {
  final String label;
  final String value;
  const SimpleDataField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 2.0),
          Text(
            value.isEmpty ? 'N/A' : value,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 138,
      height: 50,
      child: WindowCaption(
        brightness: theme.brightness,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}