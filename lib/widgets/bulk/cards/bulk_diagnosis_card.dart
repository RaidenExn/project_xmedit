import 'package:flutter/material.dart';
import 'package:project_xmedit/database_helper.dart';
import 'package:project_xmedit/models/claim_models.dart';
import 'package:project_xmedit/repositories/reference_data_repository.dart';
import 'package:project_xmedit/widgets/common/code_description_text.dart';
import 'package:project_xmedit/widgets/common/info_surface_card.dart';

/// Simplified diagnosis card
class BulkDiagnosisCard extends StatefulWidget {
  final ClaimData claim;

  const BulkDiagnosisCard({super.key, required this.claim});

  @override
  State<BulkDiagnosisCard> createState() => _BulkDiagnosisCardState();
}

class _BulkDiagnosisCardState extends State<BulkDiagnosisCard> {
  final ReferenceDataRepository _referenceData = ReferenceDataRepository();
  late Future<Map<String, CodeDescription>> _descriptionsFuture;

  @override
  void initState() {
    super.initState();
    _descriptionsFuture = _loadDescriptions();
  }

  @override
  void didUpdateWidget(covariant BulkDiagnosisCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.claim != widget.claim) {
      _descriptionsFuture = _loadDescriptions();
    }
  }

  Future<Map<String, CodeDescription>> _loadDescriptions() {
    final codes = widget.claim.diagnoses
        .map((d) => (d.code ?? '').trim().toUpperCase())
        .where((c) => c.isNotEmpty)
        .toSet();
    return _referenceData.getIcdDescriptions(codes);
  }

  String _diagnosisKey(DiagnosisData diagnosis) =>
      (diagnosis.code ?? '').trim().toUpperCase();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diagnoses = widget.claim.diagnoses;

    if (diagnoses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No diagnoses')),
      );
    }

    return FutureBuilder<Map<String, CodeDescription>>(
      future: _descriptionsFuture,
      builder: (context, snapshot) {
        final descriptions = snapshot.data ?? const <String, CodeDescription>{};
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: diagnoses.map((diagnosis) {
              final descriptionData = descriptions[_diagnosisKey(diagnosis)];
              final shortDescription = isLoading
                  ? 'Loading...'
                  : (descriptionData?.shortDescription ?? 'N/A');
              final fullDescription =
                  descriptionData?.fullDescription ?? shortDescription;

              return InfoSurfaceCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: diagnosis.type == 'Principal'
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        diagnosis.type ?? 'Unknown',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: diagnosis.type == 'Principal'
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            diagnosis.code ?? 'N/A',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          CodeDescriptionText(
                            shortDescription: shortDescription,
                            fullDescription: fullDescription,
                            style: theme.textTheme.bodySmall,
                            isLoading: isLoading,
                            enableTooltip: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
