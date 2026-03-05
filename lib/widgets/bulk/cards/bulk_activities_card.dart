import 'package:flutter/material.dart';
import 'package:project_xmedit/database_helper.dart';
import 'package:project_xmedit/models/claim_models.dart';
import 'package:project_xmedit/repositories/reference_data_repository.dart';
import 'package:project_xmedit/widgets/common/code_description_text.dart';
import 'package:project_xmedit/widgets/common/info_surface_card.dart';

/// Simplified activities card
class BulkActivitiesCard extends StatefulWidget {
  final ClaimData claim;

  const BulkActivitiesCard({super.key, required this.claim});

  @override
  State<BulkActivitiesCard> createState() => _BulkActivitiesCardState();
}

class _BulkActivitiesCardState extends State<BulkActivitiesCard> {
  final ReferenceDataRepository _referenceData = ReferenceDataRepository();
  late Future<Map<String, CodeDescription>> _descriptionsFuture;

  @override
  void initState() {
    super.initState();
    _descriptionsFuture =
        _referenceData.getActivityDescriptions(widget.claim.activities);
  }

  @override
  void didUpdateWidget(covariant BulkActivitiesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.claim != widget.claim) {
      _descriptionsFuture =
          _referenceData.getActivityDescriptions(widget.claim.activities);
    }
  }

  String _lookupKey(ActivityData activity) =>
      '${activity.type ?? ''}|${activity.code ?? ''}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activities =
        widget.claim.activities.where((a) => !a.isDeleted).toList();

    if (activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No activities')),
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
            children: activities.map((activity) {
              final descriptionData = descriptions[_lookupKey(activity)];
              final shortDescription = isLoading
                  ? 'Loading...'
                  : (descriptionData?.shortDescription ?? 'N/A');
              final fullDescription =
                  descriptionData?.fullDescription ?? shortDescription;

              return InfoSurfaceCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Code: ${activity.code ?? 'N/A'}',
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
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Qty: ${activity.quantity ?? '0'} | Net: ${activity.net ?? '0.00'}',
                            style: theme.textTheme.bodySmall,
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
