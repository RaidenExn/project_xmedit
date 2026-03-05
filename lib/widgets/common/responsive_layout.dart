import 'package:flutter/material.dart';

class ResponsiveTwoPanel extends StatelessWidget {
  final Widget leftPanel;
  final Widget rightPanel;
  final double leftPanelWidth;
  final double breakpoint;
  final double maxWidth;

  const ResponsiveTwoPanel({
    super.key,
    required this.leftPanel,
    required this.rightPanel,
    this.leftPanelWidth = 350.0,
    this.breakpoint = 900.0,
    this.maxWidth = 4200.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.surfaceContainerLow,
                        theme.colorScheme.surfaceContainer.withAlpha(220),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12)),
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outlineVariant.withAlpha(120),
                      ),
                    ),
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              theme.colorScheme.outlineVariant.withAlpha(100)),
                    ),
                    labelColor: theme.colorScheme.onSecondaryContainer,
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    tabs: const [
                      Tab(text: 'Summary'),
                      Tab(text: 'Editor'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: leftPanel,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: rightPanel,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          final content = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: leftPanelWidth,
                child: leftPanel,
              ),
              Expanded(
                child: rightPanel,
              ),
            ],
          );

          if (constraints.maxWidth > maxWidth) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: content,
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: content,
          );
        }
      },
    );
  }
}
