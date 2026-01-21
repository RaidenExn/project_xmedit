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
    this.maxWidth = 1600.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          // Compact / Tablet / Mobile Layout -> Vertical Stack
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left panel (e.g. Totals/List) on top
              // Constrain height if it's a list to avoid infinite height error?
              // Or just let it be chunks?
              // If leftPanel is scrollable (ListView), it needs a height in a Column.
              // We'll give it a flexible constraint or fixed ratio if needed.
              // Ideally, the panels manage their own scrolling or are wrapped.
              // But SingleEditorLeftPanel is a Container -> ListView.
              // In a Column, ListView tries to expand recursively.
              // We should wrap it in a limited height or Expanded/Flexible ratio?
              // For "Totals", we want it to just take necessary space.
              // Let's assume leftPanel adapts or use a constrained height box.
              // Actually, for "Bulk", left panel is the LIST. We want that expansive.
              // If < 900, maybe we use a tab/drawer approach?
              // User asked for "automatically adjust".
              // Let's try giving the top panel a max height (e.g. 40% of screen) if it's a list?
              // Or just use a defined height for mobile.
              // Let's wrap in a Flexible/Expanded logic.

              // For simplicity and "Congestion" avoidance:
              // Mobile View:
              // [Left Panel (Summary/List)] -> Height 300?
              // [Right Panel (Detail)] -> Expanded
              SizedBox(
                height: 300,
                child: leftPanel,
              ),
              const Divider(height: 1),
              Expanded(
                child: rightPanel,
              ),
            ],
          );
        } else {
          // Desktop / Wide Layout -> Side by Side
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

          // Center on ultra-wide screens
          if (constraints.maxWidth > maxWidth) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: content,
              ),
            );
          }

          return content;
        }
      },
    );
  }
}
