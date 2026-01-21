import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

import 'package:project_xmedit/models/validation_result.dart';
import 'package:project_xmedit/widgets/validation_widgets.dart';

class ScrollableOnHover extends StatelessWidget {
  final Widget child;
  const ScrollableOnHover({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _DesktopScrollBehavior(),
      child: child,
    );
  }
}

class _DesktopScrollBehavior extends ScrollBehavior {
  const _DesktopScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
      };
}

class ClaimDataSection extends StatelessWidget {
  final String title;
  final Widget child;
  final bool canStretch;
  final IconData? titleIcon;
  final Widget? titleSuffix;
  final List<Widget>? actions;

  const ClaimDataSection({
    super.key,
    required this.title,
    required this.child,
    this.canStretch = false,
    this.titleIcon,
    this.titleSuffix,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: canStretch ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
            color: colors.surfaceContainer,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.0,
              runSpacing: 8.0,
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
                      style: textStyles.titleMedium,
                    ),
                    if (titleSuffix != null) ...[
                      const SizedBox(width: 8),
                      titleSuffix!,
                    ]
                  ],
                ),
                if (actions != null)
                  Wrap(
                    spacing: 4.0,
                    runSpacing: 4.0,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
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
  final ValidationError? validationError;

  const DataFieldWithCopy(
      {super.key,
      required this.label,
      required this.value,
      this.validationError});

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: theme.textTheme.bodySmall),
                    if (validationError != null) ...[
                      const SizedBox(width: 4),
                      ValidationIndicator(error: validationError!, size: 16),
                    ],
                  ],
                ),
                const SizedBox(height: 2.0),
                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: theme.textTheme.bodyLarge,
                  overflow: TextOverflow
                      .ellipsis, // Optional: handle very long text gracefully
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
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
  final ValidationError? validationError;

  const SimpleDataField(
      {super.key,
      required this.label,
      required this.value,
      this.validationError});

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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              if (validationError != null) ...[
                const SizedBox(width: 4),
                ValidationIndicator(error: validationError!, size: 16),
              ],
            ],
          ),
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

class HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final String? tooltip;

  const HeaderActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = TextButton.icon(
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        foregroundColor: color,
      ),
      icon: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onPressed,
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
