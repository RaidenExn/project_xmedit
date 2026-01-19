import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_xmedit/notifiers.dart';
import 'package:project_xmedit/database_helper.dart';
import 'package:project_xmedit/models/claim_models.dart';
import 'package:project_xmedit/widgets/common/custom_table.dart';

const Map<String, int> _diagnosisColumnFlex = {
  'code': 3,
  'desc': 10,
  'principal': 2,
  'actions': 1,
};

class DiagnosisCard extends StatelessWidget {
  const DiagnosisCard({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClaimDataNotifier>();
    final diagnoses = notifier.claimData!.diagnoses;

    if (diagnoses.isEmpty) {
      return const Center(
        child:
            Text("No diagnoses found. Use the 'Add' button in the title bar."),
      );
    }

    return Column(
      children: [
        const _DiagnosisTableHeader(),
        const Divider(height: 1),
        ...diagnoses.asMap().entries.map((entry) {
          final int idx = entry.key;
          final diag = entry.value;
          return _DiagnosisDataRow(
            key: ValueKey(diag.id),
            notifier: notifier,
            diag: diag,
            isZebra: idx.isEven,
          );
        })
      ],
    );
  }
}

class _DiagnosisTableHeader extends StatelessWidget {
  const _DiagnosisTableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return CustomTableHeader(
      children: [
        Expanded(
          flex: _diagnosisColumnFlex['code']!,
          child: Text('Code', style: style),
        ),
        Expanded(
          flex: _diagnosisColumnFlex['desc']!,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Description', style: style),
          ),
        ),
        Expanded(
          flex: _diagnosisColumnFlex['principal']!,
          child: Center(child: Text('Principal', style: style)),
        ),
        Expanded(
          flex: _diagnosisColumnFlex['actions']!,
          child: Center(child: Text('Actions', style: style)),
        ),
      ],
    );
  }
}

class _DiagnosisDataRow extends StatefulWidget {
  final ClaimDataNotifier notifier;
  final DiagnosisData diag;
  final bool isZebra;

  const _DiagnosisDataRow(
      {super.key,
      required this.notifier,
      required this.diag,
      required this.isZebra});

  @override
  State<_DiagnosisDataRow> createState() => _DiagnosisDataRowState();
}

class _DiagnosisDataRowState extends State<_DiagnosisDataRow> {
  late Future<String?> _descriptionFuture;

  @override
  void initState() {
    super.initState();
    _descriptionFuture =
        DatabaseHelper().getIcd10Description(widget.diag.code ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.notifier.isDiagnosisEditingEnabled;
    final theme = Theme.of(context);
    final textStyle =
        TextStyle(fontSize: 14, color: theme.colorScheme.onSurface);
    final isPrincipal = widget.diag.type == 'Principal';

    final Color iconColor = isEditing
        ? (isPrincipal
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant)
        : theme.disabledColor;

    return FutureBuilder<String?>(
      future: _descriptionFuture,
      builder: (context, snapshot) {
        final description = snapshot.connectionState == ConnectionState.done
            ? (snapshot.data ?? 'N/A')
            : 'Loading...';

        return CustomDataRow(
          isZebra: widget.isZebra,
          isHighlighted: isPrincipal,
          children: [
            Expanded(
              flex: _diagnosisColumnFlex['code']!,
              child: Text(widget.diag.code ?? '', style: textStyle),
            ),
            Expanded(
              flex: _diagnosisColumnFlex['desc']!,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  description,
                  style: textStyle,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            Expanded(
              flex: _diagnosisColumnFlex['principal']!,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: IconButton(
                    key: ValueKey(isPrincipal),
                    icon: Icon(
                      isPrincipal
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 20,
                      color: iconColor,
                    ),
                    onPressed: isEditing
                        ? () => widget.notifier
                            .setPrincipalDiagnosis(widget.diag.id)
                        : null,
                    splashRadius: 20,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: _diagnosisColumnFlex['actions']!,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color:
                      isEditing ? theme.colorScheme.error : theme.disabledColor,
                  onPressed: isEditing
                      ? () => widget.notifier.deleteDiagnosis(widget.diag.id)
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
